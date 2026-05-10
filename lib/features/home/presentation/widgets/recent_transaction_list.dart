import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/theme/colors.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textHeading
                    : AppColorsLight.textHeading,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "View all",
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.primary
                      : AppColorsLight.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KiseCardHolder(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFFA855F7),
              ),
            ),
            title: Text(
              "Education",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textHeading
                    : AppColorsLight.textHeading,
              ),
            ),
            subtitle: Text(
              "something. April 15",
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textHint
                    : AppColorsLight.textHint,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              "-20,000.00 ETB",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark
                    ? AppColorsDark.textHeading
                    : AppColorsLight.textHeading,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
