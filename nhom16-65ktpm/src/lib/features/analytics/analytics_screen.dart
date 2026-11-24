import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/fund_transaction_model.dart';
import '../../data/repositories/fund_repository.dart';
import 'analytics_service.dart';
import 'widgets/cashflow_bar_chart.dart';
import 'widgets/challenge_pie_chart.dart';
import 'widgets/fund_line_chart.dart';

// Màn hình Báo cáo & Thống kê minh bạch quỹ.
// Giai đoạn 4 - C5: toàn bộ màn hình (3 thẻ, tiến độ mục tiêu, 3 biểu đồ)
// dùng dữ liệu thật từ FundRepository.getTransactions; các trạng thái
// tải / lỗi / rỗng đều có nút nạp lại số liệu.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _fundGoal =
      100000000.0; // Mục tiêu gây quỹ — khớp với Dashboard.

  late Future<List<FundTransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = FundRepository.instance.getTransactions();
  }

  /// Nạp lại danh sách giao dịch từ Sổ Quỹ.
  /// Gắn với nút "Thử lại" ở trạng thái lỗi và nút "Tải lại" ở trạng
  /// thái chưa có giao dịch, để không phải mở lại màn hình.
  void _reload() {
    setState(() {
      _transactionsFuture = FundRepository.instance.getTransactions();
    });
  }

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  Widget _summaryCard(String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                _money(value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê quỹ từ thiện')),
      body: FutureBuilder<List<FundTransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Đang tải số liệu...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Không tải được số liệu quỹ.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final txs = snapshot.data ?? const <FundTransactionModel>[];
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('Chưa có giao dịch quỹ.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          const service = AnalyticsService();
          final income = service.totalIncome(txs);
          final expense = service.totalExpense(txs);
          final balance = service.balance(txs);
          final goalProgress = (balance / _fundGoal).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _summaryCard(
                    'Tổng thu',
                    income,
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                  _summaryCard(
                    'Tổng chi',
                    expense,
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                  _summaryCard(
                    'Số dư',
                    balance,
                    Colors.blue,
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tiến độ mục tiêu: ${_money(balance)} / ${_money(_fundGoal)}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: goalProgress),
              const SizedBox(height: 24),
              const Text(
                'Biến động số dư (7 ngày)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FundLineChart(points: service.balanceByDay(txs)),
              const SizedBox(height: 24),
              const Text(
                'Thu / chi theo tháng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CashflowBarChart(points: service.incomeExpenseByMonth(txs)),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.square, color: Colors.green, size: 14),
                  Text(' Thu   '),
                  Icon(Icons.square, color: Colors.red, size: 14),
                  Text(' Chi'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Đóng góp theo danh mục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ChallengePieChart(shares: service.contributionByChallenge(txs)),
            ],
          );
        },
      ),
    );
  }
}
