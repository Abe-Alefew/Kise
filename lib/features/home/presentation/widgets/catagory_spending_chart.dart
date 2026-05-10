import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class CategorySpendingChart extends StatelessWidget {
  const CategorySpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Spending by Category",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColorsDark.textHeading
                : AppColorsLight.textHeading,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColorsDark.card : AppColorsLight.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColorsDark.secondaryBg
                  : AppColorsLight.secondaryBg,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: Color(0xFFA855F7),
                        value: 20000,
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Color(0xFFA855F7)),
                  const SizedBox(width: 8),
                  Text(
                    "Education",
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textBody
                          : AppColorsLight.textBody,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "20,000",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textHeading
                          : AppColorsLight.textHeading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
