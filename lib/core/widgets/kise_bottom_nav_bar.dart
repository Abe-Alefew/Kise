import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/theme/app_dimensions.dart';

class KiseBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const KiseBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColorsDark.border : AppColorsLight.textHint.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: LucideIcons.layoutGrid,
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
              isDark: isDark,
            ),
            _NavBarItem(
              icon: LucideIcons.arrowRightLeft,
              label: 'Transactions',
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
              isDark: isDark,
            ),
            _NavBarItem(
              icon: LucideIcons.target,
              label: 'Goals',
              isSelected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
              isDark: isDark,
            ),
            _NavBarItem(
              icon: LucideIcons.creditCard,
              label: 'Debt Book',
              isSelected: selectedIndex == 3,
              onTap: () => onItemSelected(3),
              isDark: isDark,
            ),
            _NavBarItem(
              icon: LucideIcons.settings,
              label: 'Settings',
              isSelected: selectedIndex == 4,
              onTap: () => onItemSelected(4),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;
    final inactiveColor = isDark ? AppColorsDark.textHint : AppColorsLight.textHint;
    final activeBgColor = isDark 
        ? AppColorsDark.primary.withValues(alpha: 0.15) 
        // @ TODO: define this color in App theme
        : const Color(0xFFF6EADB); // A color close to the cream in the screenshot, or AppColorsLight.primary.withValues(alpha: 0.1)


    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected ? activeBgColor : Colors.transparent,
              borderRadius: AppDimensions.radiusLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppDimensions.xs,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: AppDimensions.lg,
                ),
                Text(
                  label,
                  style: AppTextStyles.micro.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
