import 'data/mock_fund_data.dart';

// Logic thuần, KHÔNG tính toán trong widget.
// Nhận vào 'List<MockFundTx>', trả số liệu cho các biểu đồ.
// Sprint 4: chỉ đổi đầu vào thành 'List<FundTransactionModel>' thật
// (cùng các trường isIncome/amount/date/challenge) — các hàm giữ nguyên.

class BalancePoint {
  const BalancePoint(this.label, this.balance);
  final String label; // vd 'T2', 'T3'...
  final double balance;
}

class MonthPoint {
  const MonthPoint(this.label, this.income, this.expense);
  final String label; // vd 'T9', 'T10'
  final double income;
  final double expense;
}

class ChallengeShare {
  const ChallengeShare(this.challenge, this.amount);
  final String challenge;
  final double amount;
}

class AnalyticsService {
  const AnalyticsService();

  double totalIncome(List<MockFundTx> txs) =>
      txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);

  double totalExpense(List<MockFundTx> txs) =>
      txs.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);

  double balance(List<MockFundTx> txs) => totalIncome(txs) - totalExpense(txs);

  /// Số dư cuối mỗi ngày trong 7 ngày gần nhất (cũ -> mới).
  /// Số dư ngày D = tổng thu - tổng chi của mọi giao dịch tới hết ngày D.
  List<BalancePoint> balanceByDay(List<MockFundTx> txs, {int days = 7}) {
    const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final now = DateTime.now();
    final points = <BalancePoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final endOfDay = day.add(const Duration(hours: 23, minutes: 59));
      final upToDay = txs.where((t) => !t.date.isAfter(endOfDay));
      final bal = upToDay.fold<double>(
        0,
        (s, t) => s + (t.isIncome ? t.amount : -t.amount),
      );
      points.add(BalancePoint(weekdayLabels[day.weekday - 1], bal));
    }
    return points;
  }

  /// Thu/chi theo từng tháng (3 tháng gần nhất, cũ -> mới).
  List<MonthPoint> incomeExpenseByMonth(List<MockFundTx> txs) {
    final now = DateTime.now();
    final points = <MonthPoint>[];
    for (var back = 2; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      final inMonth = txs.where(
        (t) => t.date.year == month.year && t.date.month == month.month,
      );
      points.add(
        MonthPoint(
          'T${month.month}',
          inMonth.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount),
          inMonth.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount),
        ),
      );
    }
    return points;
  }

  /// Tỷ trọng đóng góp theo từng loại thử thách (chỉ tính khoản thu).
  List<ChallengeShare> contributionByChallenge(List<MockFundTx> txs) {
    final map = <String, double>{};
    for (final t in txs) {
      if (!t.isIncome || t.challenge.isEmpty) continue;
      map[t.challenge] = (map[t.challenge] ?? 0) + t.amount;
    }
    return map.entries.map((e) => ChallengeShare(e.key, e.value)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}
