import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/home_dashboard_models.dart';

class TrendChart extends StatelessWidget {
  final List<HomeTrendPoint> trend;

  const TrendChart({
    super.key,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return Center(
        child: Text(
          'No trend data yet',
          style: TextStyle(color: AppColorsLight.textHint),
        ),
      );
    }

    final maxValue = trend.fold<double>(
      0,
      (max, point) {
        final peak = point.income > point.expense ? point.income : point.expense;
        return peak > max ? peak : max;
      },
    );
    final chartMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMaxY,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trend.length) {
                  return Text(
                    trend[index].month,
                    style: const TextStyle(
                      color: AppColorsLight.textHint,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < trend.length; i++)
                FlSpot(i.toDouble(), trend[i].expense),
            ],
            isCurved: true,
            color: const Color(0xFFEAB308),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFEAB308).withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < trend.length; i++)
                FlSpot(i.toDouble(), trend[i].income),
            ],
            isCurved: true,
            color: const Color(0xFF22C55E),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF22C55E).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
