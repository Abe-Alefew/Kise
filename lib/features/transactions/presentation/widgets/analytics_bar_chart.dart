import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({super.key});

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      height: 220,

      child: BarChart(

        BarChartData(

          alignment:
              BarChartAlignment.spaceAround,

          maxY: 20000,

          borderData:
              FlBorderData(show: false),

          gridData:
              FlGridData(show: false),

          titlesData: FlTitlesData(

            topTitles:
                const AxisTitles(),

            rightTitles:
                const AxisTitles(),

            leftTitles:
                const AxisTitles(),

            bottomTitles: AxisTitles(

              sideTitles: SideTitles(

                showTitles: true,

                getTitlesWidget:
                    (value, meta) {

                  final months = [
                    "Jan",
                    "Feb",
                    "Mar",
                    "Apr",
                    "May",
                  ];

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                            top: 8),

                    child: Text(
                      months[value.toInt()],
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: [

            _buildBar(0, 5000),
            _buildBar(1, 8000),
            _buildBar(2, 12000),
            _buildBar(3, 15000),
            _buildBar(4, 10000),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(
      int x,
      double amount,
      ) {

    return BarChartGroupData(

      x: x,

      barRods: [

        BarChartRodData(

          toY: amount,

          width: 18,

          borderRadius:
              BorderRadius.circular(8),

          color:
              const Color(0xFFD4AF37),
        ),
      ],
    );
  }
}