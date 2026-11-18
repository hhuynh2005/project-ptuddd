import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../analytics_service.dart';

/// Biểu đồ đường: biến động số dư quỹ 7 ngày gần nhất.
class FundLineChart extends StatelessWidget {
  const FundLineChart({super.key, required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa đủ dữ liệu để vẽ biểu đồ.')),
      );
    }
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].balance),
    ];
    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2 + 10000;
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
