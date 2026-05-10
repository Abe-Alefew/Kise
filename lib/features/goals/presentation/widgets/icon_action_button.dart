import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';

class IconActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDark; 

  const IconActionBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColorsLight.primary.withValues(alpha: 0.1) : ( isDark ? AppColorsDark.secondaryBg : AppColorsLight.secondaryBg ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? AppColorsLight.primary : ( isDark ? AppColorsDark.textHint : AppColorsLight.textHint ),
        onPressed: onTap,
      ),
    );
  }
}
