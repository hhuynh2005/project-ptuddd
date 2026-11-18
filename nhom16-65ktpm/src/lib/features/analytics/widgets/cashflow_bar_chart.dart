import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../analytics_service.dart';

/// Biểu đồ cột: thu (xanh) / chi (đỏ) theo tháng.
class CashflowBarChart extends StatelessWidget {
  const CashflowBarChart({super.key, required this.points});

  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu thu/chi.')),
      );
    }
    final maxVal = points
        .expand((p) => [p.income, p.expense])
        .reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2 + 10000,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  '${(value / 1000).round()}k',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    points[i].label,
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: points[i].income,
                    color: Colors.green,
                    width: 14,
                  ),
                  BarChartRodData(
                    toY: points[i].expense,
                    color: Colors.red,
                    width: 14,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
