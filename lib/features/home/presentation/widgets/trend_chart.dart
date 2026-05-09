import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr']; // 6-month history
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(months[value.toInt()], 
                    style: const TextStyle(color: AppColorsLight.textHint, fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 500), FlSpot(5, 30000)], // Expenses
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
          LineChartBarData(
            spots: const [FlSpot(0, 200), FlSpot(5, 20000)], // Income
            isCurved: true,
            color: AppColorsLight.primary,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColorsLight.primary.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}