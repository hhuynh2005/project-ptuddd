import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'analytics_service.dart';
import 'data/mock_fund_data.dart';
import 'widgets/cashflow_bar_chart.dart';
import 'widgets/challenge_pie_chart.dart';
import 'widgets/fund_line_chart.dart';

// Màn hình Báo cáo & Thống kê minh bạch quỹ (Sprint 1: mock data).
// 3 thẻ Tổng thu / Tổng chi / Số dư + tiến độ mục tiêu + 3 biểu đồ.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _fundGoal = 1000000.0; // Mục tiêu gây quỹ (mock).

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
    const service = AnalyticsService();
    final txs = mockTransactions;
    final income = service.totalIncome(txs);
    final expense = service.totalExpense(txs);
    final balance = service.balance(txs);
    final goalProgress = (balance / _fundGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê quỹ từ thiện')),
      body: txs.isEmpty
          ? const Center(child: Text('Chưa có giao dịch quỹ.'))
          : ListView(
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
                  'Đóng góp theo loại thử thách',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ChallengePieChart(shares: service.contributionByChallenge(txs)),
              ],
            ),
    );
  }
}
