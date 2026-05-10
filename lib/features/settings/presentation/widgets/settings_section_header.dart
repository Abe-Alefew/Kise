import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: AppDimensions.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: (isDark ? AppTextStylesDark.h3 : AppTextStyles.h3).copyWith(
                  fontSize: 15,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.micro.copyWith(
                    color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
