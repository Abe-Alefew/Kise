import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/widgets/kise_progress_bar.dart';
import '../../../../core/theme/colors.dart';

class BudgetStatusCard extends StatelessWidget {
  final double spendRatio;
  const BudgetStatusCard({super.key, required this.spendRatio});

  @override
  Widget build(BuildContext context) {
    return KiseCardHolder(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.balance, color: AppColorsLight.primary),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Budget Spender",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Good Balance between spending and saving",
                      style: TextStyle(color: AppColorsLight.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Spend ration",
                  style: TextStyle(color: AppColorsLight.textHint, fontSize: 12),
                ),
                Text(
                  "${(spendRatio * 100).toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            KiseProgressBar(progress: spendRatio), // Zeamanuel's core widget
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColorsLight.primary,
                ),
                SizedBox(width: 4),
                Text(
                  "Try to push your savings a bit higher.",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
