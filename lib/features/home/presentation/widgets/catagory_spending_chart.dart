import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategorySpendingChart extends StatelessWidget {
  const CategorySpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Spending by Category",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
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
                        color: const Color(0xFFA855F7), // Purple from image
                        value: 20000,
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Color(0xFFA855F7)),
                  SizedBox(width: 8),
                  Text("Education", style: TextStyle(color: Colors.grey)),
                  Spacer(),
                  Text("20,000", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
