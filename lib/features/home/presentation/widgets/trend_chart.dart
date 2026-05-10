import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = [
                  'Nov',
                  'Dec',
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                ]; // 6-month history
                final textColor = isDark
                    ? AppColorsDark.textHint
                    : AppColorsLight.textHint;
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: TextStyle(color: textColor, fontSize: 12),
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
            spots: const [FlSpot(0, 500), FlSpot(5, 30000)], // Expenses
            isCurved: true,
            color: AppColorsLight.error,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppColorsLight.error.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: const [FlSpot(0, 200), FlSpot(5, 20000)], // Income
            isCurved: true,
            color: AppColorsLight.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppColorsLight.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
