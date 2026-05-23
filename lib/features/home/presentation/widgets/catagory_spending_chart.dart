import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/home_dashboard_models.dart';

class CategorySpendingChart extends StatelessWidget {
  final List<HomeCategorySpending> categories;
  final String currency;

  static const _chartColors = [
    Color(0xFFA855F7),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  const CategorySpendingChart({
    super.key,
    required this.categories,
    this.currency = 'ETB',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
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
          child: categories.isEmpty
              ? SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No category spending this month',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textHint
                            : AppColorsLight.textHint,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: [
                            for (var i = 0; i < categories.length; i++)
                              PieChartSectionData(
                                color: _chartColors[i % _chartColors.length],
                                value: categories[i].amount,
                                title: '',
                                radius: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      for (var i = 0; i < categories.length && i < 4; i++)
                        _CategoryLegendRow(
                          color: _chartColors[i % _chartColors.length],
                          label: categories[i].category,
                          amount: categories[i].amount,
                          currency: currency,
                          isDark: isDark,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final String currency;
  final bool isDark;

  const _CategoryLegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColorsDark.textBody : AppColorsLight.textBody,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textHeading
                  : AppColorsLight.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}
