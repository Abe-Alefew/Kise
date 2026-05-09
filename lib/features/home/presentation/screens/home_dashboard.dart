import 'package:flutter/material.dart';
import '../widgets/balance_card.dart';
import '../widgets/allowance_card.dart';
import '../widgets/budget_status_card.dart';
import '../widgets/trend_chart.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back,", style: TextStyle(color: Colors.grey)),
              const Text(
                "Betsinat Wendwesen",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const BalanceCard(
                totalBalance: 10000.00,
                income: 30000.00,
                expenses: 20000.00,
              ),
              const SizedBox(height: 20),
              const AllowanceCard(),
              const SizedBox(height: 16),
              const BudgetStatusCard(spendRatio: 0.67),
              const SizedBox(height: 24),
              const Text(
                "6-month trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 250, child: TrendChart()),
            ],
          ),
        ),
      ),
    );
  }
}
