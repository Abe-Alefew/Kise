import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/theme/colors.dart';

class AllowanceCard extends StatelessWidget {
  const AllowanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return KiseCardHolder(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Icon(
            Icons.lightbulb_outline,
            color: isDark ? AppColorsDark.primary : AppColorsLight.primary,
          ),
          title: Text(
            "Set your allowance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColorsDark.primary : AppColorsLight.primary,
            ),
          ),
          subtitle: Text(
            "Go to Settings to set your monthly budget and unlock spending alerts.",
            style: TextStyle(fontSize: 13, color: isDark ? AppColorsDark.textBody : AppColorsLight.textBody),
          ),
        ),
      ),
    );
  }
}
