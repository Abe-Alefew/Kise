import 'package:flutter/material.dart';

// Feature Widgets
import '../widgets/balance_card.dart';
import '../widgets/allowance_card.dart';
import '../widgets/budget_status_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/catagory_spending_chart.dart';
import '../widgets/recent_transaction_list.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                "Welcome back,",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Text(
                "Betsinat Wendwesen",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              // 1. Gold Balance Card
              const BalanceCard(
                totalBalance: 10000.00,
                income: 30000.00,
                expenses: 20000.00,
              ),

              const SizedBox(height: 24),

              // 2. Allowance Reminder 
              const AllowanceCard(),

              const SizedBox(height: 16),

              // 3. Budget Status 
              const BudgetStatusCard(spendRatio: 0.67),

              const SizedBox(height: 32),

              // 4. 6-Month Trend Chart 
              const Text(
                "6-month trend",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 200, child: TrendChart()),
              const SizedBox(height: 32),
              const CategorySpendingChart(),
              const SizedBox(height: 32),
              const RecentTransactionsList(),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}
