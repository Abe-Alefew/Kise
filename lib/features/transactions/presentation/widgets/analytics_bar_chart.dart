import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsBarChart extends StatelessWidget {

  final String selectedFilter;

  const AnalyticsBarChart({
    super.key,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      height: 250,

      child: BarChart(

        BarChartData(

          maxY: 50000,

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
                    "Oct",
                    "Nov",
                    "Dec",
                    "Jan",
                    "Feb",
                    "Mar",
                  ];

                  return Padding(

                    padding:
                        const EdgeInsets.only(
                            top: 10),

                    child: Text(
                      months[value.toInt()],
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData>
      _buildBarGroups() {

    /// ALL
    if (selectedFilter == "All") {

      return [

        _doubleBar(0, 4500, 3800),
        _doubleBar(1, 4800, 4200),
        _doubleBar(2, 4300, 4500),
        _doubleBar(3, 5200, 3900),
        _doubleBar(4, 4700, 4100),
        _doubleBar(5, 5600, 4300),
      ];
    }

    /// INCOME ONLY
    if (selectedFilter == "Income") {

      return [

        _singleBar(
          0,
          4500,
          Colors.green,
        ),

        _singleBar(
          1,
          5000,
          Colors.teal,
        ),

        _singleBar(
          2,
          4300,
          Colors.lightGreen,
        ),

        _singleBar(
          3,
          5500,
          Colors.green,
        ),

        _singleBar(
          4,
          4700,
          Colors.teal,
        ),

        _singleBar(
          5,
          6000,
          Colors.lightGreen,
        ),
      ];
    }

    /// EXPENSE ONLY
    return [

      _singleBar(
        0,
        3800,
        const Color(0xFFD4AF37),
      ),

      _singleBar(
        1,
        4200,
        Colors.orange,
      ),

      _singleBar(
        2,
        4500,
        Colors.amber,
      ),

      _singleBar(
        3,
        3900,
        const Color(0xFFD4AF37),
      ),

      _singleBar(
        4,
        4100,
        Colors.orange,
      ),

      _singleBar(
        5,
        4300,
        Colors.amber,
      ),
    ];
  }

  BarChartGroupData _doubleBar(
      int x,
      double income,
      double expense,
      ) {

    return BarChartGroupData(

      x: x,

      barsSpace: 6,

      barRods: [

        BarChartRodData(

          toY: income,

          width: 12,

          color: Colors.green,

          borderRadius:
              BorderRadius.circular(4),
        ),

        BarChartRodData(

          toY: expense,

          width: 12,

          color:
              const Color(0xFFD4AF37),

          borderRadius:
              BorderRadius.circular(4),
        ),
      ],
    );
  }

  BarChartGroupData _singleBar(
      int x,
      double value,
      Color color,
      ) {

    return BarChartGroupData(

      x: x,

      barRods: [

        BarChartRodData(

          toY: value,

          width: 18,

          color: color,

          borderRadius:
              BorderRadius.circular(4),
        ),
      ],
    );
  }
}