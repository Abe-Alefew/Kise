import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double income;
  final double expenses;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorsLight.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL BALANCE",
            style: TextStyle(
              color: AppColorsLight.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${totalBalance.toStringAsFixed(2)} ETB",
            style: const TextStyle(
              color: AppColorsLight.textOnPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(Icons.trending_up, "Income", income),
              _buildStat(Icons.trending_down, "Expenses", expenses),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String title, double amount) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColorsLight.textOnPrimary.withOpacity(0.2),
          child: Icon(icon, color: AppColorsLight.textOnPrimary, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: AppColorsLight.textOnPrimary, fontSize: 12),
            ),
            Text(
              "${amount.toStringAsFixed(2)} ETB",
              style: const TextStyle(
                color: AppColorsLight.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
