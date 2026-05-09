import 'package:flutter/material.dart';
import '../../../core/widgets/kise_pill_filter.dart';

class TestPillFilterPage extends StatefulWidget {
  const TestPillFilterPage({super.key});

  @override
  State<TestPillFilterPage> createState() => _TestPillFilterPageState();
}

class _TestPillFilterPageState extends State<TestPillFilterPage> {
  String selected = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          KisePillFilter(
            options: ["All", "Income", "Expense"],
            selected: selected,
            onSelected: (value) {
              setState(() {
                selected = value;
              });
            },
            height: 30,
          ),

          const SizedBox(height: 30),

        ],
        ),
      ),
    );
  }
}
