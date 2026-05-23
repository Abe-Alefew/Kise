import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/widgets/kise_progress_bar.dart';
import '../../../../core/theme/colors.dart';

class BudgetStatusCard extends StatelessWidget {
  final double spendRatio;
  final String personality;
  final String tip;

  const BudgetStatusCard({
    super.key,
    required this.spendRatio,
    required this.personality,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  child: const Icon(
                    Icons.balance,
                    color: AppColorsLight.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personality,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Spending personality for this cycle',
                        style: TextStyle(
                          color: AppColorsLight.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spend ratio',
                  style: TextStyle(
                    color: AppColorsLight.textHint,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(spendRatio * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textHeading
                        : AppColorsLight.textHeading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            KiseProgressBar(progress: spendRatio.clamp(0.0, 1.0)),
            if (tip.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColorsLight.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
