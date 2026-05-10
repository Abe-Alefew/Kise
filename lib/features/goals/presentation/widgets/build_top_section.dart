import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/goals/presentation/widgets/goal_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget buildTopSection(BuildContext context, GoalCard widget) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = widget.goal.progressPercentage;
    final int percentageInt = (progress * 100).round();
    final bool isFull = percentageInt >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: AppDimensions.sm, 
              children: [
                Icon(
                  isFull ? LucideIcons.checkCircle : LucideIcons.target,
                  color: isFull ? AppColorsLight.success : AppColorsLight.primary,
                  size: 20,
                ),
                Text(
                  widget.goal.title,
                  style: isDark ? AppTextStylesDark.h3 : AppTextStyles.h3,
                ),
                if (widget.goal.isLocked) ...[
                  const Icon(LucideIcons.lock, size: 16, color: AppColorsLight.textHint),
                ]
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                '$percentageInt%',
                style: AppTextStyles.micro.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.goal.period,
              style: AppTextStyles.micro.copyWith(color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint),
            ),
            Text(
              widget.goal.dueDate,
              style: AppTextStyles.micro.copyWith(color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),

        KiseProgressBar(progress: progress, height: 8),
        
        const SizedBox(height: AppDimensions.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.goal.currentAmount.toStringAsFixed(0)} ETB',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint,
              ),
            ),
            Text(
              '${widget.goal.targetAmount.toStringAsFixed(0)} ETB',
              style: AppTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }
