import 'package:flutter/material.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';

class AllowanceCard extends StatelessWidget {
  final HomeDashboardAllowance allowance;

  const AllowanceCard({
    super.key,
    required this.allowance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!allowance.isConfigured) {
      return KiseCardHolder(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: AppColorsLight.primary,
            ),
            title: Text(
              'Set your allowance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColorsLight.primary,
              ),
            ),
            subtitle: Text(
              'Go to Settings to set your monthly budget and unlock spending alerts.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColorsDark.textBody : AppColorsLight.textBody,
              ),
            ),
          ),
        ),
      );
    }

    final spendPercent = allowance.monthlyAmount > 0
        ? (allowance.cycleSpend / allowance.monthlyAmount).clamp(0.0, 1.0)
        : 0.0;

    return KiseCardHolder(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: AppColorsLight.primary),
                const SizedBox(width: 12),
                Text(
                  'Monthly allowance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? AppColorsDark.textHeading
                        : AppColorsLight.textHeading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${allowance.cycleSpend.toStringAsFixed(2)} / ${allowance.monthlyAmount.toStringAsFixed(2)} spent this cycle',
              style: TextStyle(
                color: isDark ? AppColorsDark.textBody : AppColorsLight.textBody,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: spendPercent,
              backgroundColor: AppColorsLight.primary.withOpacity(0.1),
              color: AppColorsLight.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
