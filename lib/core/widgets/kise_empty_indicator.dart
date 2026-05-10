import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KiseEmptyIndicator extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const KiseEmptyIndicator({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = LucideIcons.packageOpen,
  });

  @override
  State<KiseEmptyIndicator> createState() => _KiseEmptyIndicatorState();
}

class _KiseEmptyIndicatorState extends State<KiseEmptyIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColorsDark.textHint : AppColorsLight.textHint;

    return Center(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.xl),
                decoration: BoxDecoration(
                  color: (isDark ? AppColorsDark.primary : AppColorsLight.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 64,
                  color: isDark ? AppColorsDark.primary : AppColorsLight.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                widget.title,
                style: (isDark ? AppTextStylesDark.h3 : AppTextStyles.h3).copyWith(
                  color: isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppDimensions.xs),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: (isDark ? AppTextStylesDark.bodySm : AppTextStyles.bodySm).copyWith(
                    color: hintColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
