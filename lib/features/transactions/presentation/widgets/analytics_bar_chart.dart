import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/transaction_datasource.dart';

class AnalyticsBarChart extends StatelessWidget {

  final String selectedFilter;
  final String selectedRange;

  const AnalyticsBarChart({
    super.key,
    required this.selectedFilter,
    this.selectedRange = '1 Month',
  });

  static const _allMonths = [
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov',
    'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
  ];

  // Income source colors
  static const _incomeColors = {
    'Salary':     Color(0xFF2BAB68),
    'Freelance':  Color(0xFF1A7A4A),
    'Investment': Color(0xFF56C98A),
    'Bonus':      Color(0xFF0D5C35),
  };

  // Expense category colors
  static const _expenseColors = {
    'Housing':       Color(0xFFDDA22C),
    'Food':          Color(0xFFE8B84B),
    'Education':     Color(0xFFAF7E1D),
    'Shopping':      Color(0xFFF0CC7A),
    'Transport':     Color(0xFF8A6010),
    'Entertainment': Color(0xFFCB9020),
    'Health':        Color(0xFFD4A050),
    'Travel':        Color(0xFF6B4A0A),
  };

  List<String> get _visibleMonths {
    switch (selectedRange) {
      case '1 Month':  return _allMonths.sublist(11);
      case '3 Months': return _allMonths.sublist(9);
      case '6 Months': return _allMonths.sublist(6);
      default:         return _allMonths;
    }
  }

  // Returns { month: { category: amount } }
  Map<String, Map<String, double>> _groupBy(String type) {
    final result = <String, Map<String, double>>{};
    for (final t in TransactionDatasource.transactions) {
      if (t.type == type) {
        result[t.month] ??= {};
        result[t.month]![t.category] =
            (result[t.month]![t.category] ?? 0) + t.amount;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final months     = _visibleMonths;
    final incomeData  = _groupBy('Income');
    final expenseData = _groupBy('Expense');

    // Compute maxY
    double maxY = 10000;
    for (final m in months) {
      final inc = (incomeData[m] ?? {}).values.fold(0.0, (a, b) => a + b);
      final exp = (expenseData[m] ?? {}).values.fold(0.0, (a, b) => a + b);
      if (selectedFilter != 'Expenses') maxY = maxY > inc ? maxY : inc;
      if (selectedFilter != 'Income')   maxY = maxY > exp ? maxY : exp;
    }
    maxY = ((maxY / 10000).ceil() * 10000).toDouble();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < months.length; i++) {
      final m = months[i];

      if (selectedFilter == 'All') {
        // Double bar: total income vs total expense
        final inc = (incomeData[m] ?? {}).values.fold(0.0, (a, b) => a + b);
        final exp = (expenseData[m] ?? {}).values.fold(0.0, (a, b) => a + b);
        barGroups.add(_doubleBar(i, inc, exp));

      } else if (selectedFilter == 'Income') {
        // Stacked bar per income source
        final cats = incomeData[m] ?? {};
        barGroups.add(_stackedBar(i, cats, _incomeColors));

      } else {
        // Stacked bar per expense category
        final cats = expenseData[m] ?? {};
        barGroups.add(_stackedBar(i, cats, _expenseColors));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildLegend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              groupsSpace: months.length > 6 ? 4 : 10,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      final label = value >= 1000
                          ? '${(value / 1000).toStringAsFixed(0)}k'
                          : value.toInt().toString();
                      return Text(
                        label,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          months[idx],
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    if (selectedFilter == 'All') {
      return Row(children: [
        _legendDot(const Color(0xFF2BAB68), 'Income'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFDDA22C), 'Expense'),
      ]);
    }
    final colorMap = selectedFilter == 'Income' ? _incomeColors : _expenseColors;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: colorMap.entries
          .map((e) => _legendDot(e.value, e.key))
          .toList(),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }

  BarChartGroupData _doubleBar(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: income,
          width: 10,
          color: const Color(0xFF2BAB68),
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: expense,
          width: 10,
          color: const Color(0xFFDDA22C),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  BarChartGroupData _stackedBar(
    int x,
    Map<String, double> categories,
    Map<String, Color> colorMap,
  ) {
    double total = categories.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return BarChartGroupData(
        x: x,
        barRods: [BarChartRodData(toY: 0, width: 16)],
      );
    }

    final rodStackItems = <BarChartRodStackItem>[];
    double from = 0;
    for (final entry in categories.entries) {
      final to = from + entry.value;
      rodStackItems.add(BarChartRodStackItem(
        from,
        to,
        colorMap[entry.key] ?? Colors.grey,
      ));
      from = to;
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          width: 18,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: rodStackItems,
        ),
      ],
    );
  }
}
