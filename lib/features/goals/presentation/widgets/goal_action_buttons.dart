import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/features/goals/presentation/widgets/icon_action_button.dart';

class GoalActionButtons extends StatelessWidget {
  final VoidCallback onDepositTap;
  final VoidCallback onEditTap;
  final VoidCallback onLockTap;
  final VoidCallback onDeleteTap;
  final bool isLocked;

  const GoalActionButtons({
    super.key,
    required this.onDepositTap,
    required this.onEditTap,
    required this.onLockTap,
    required this.onDeleteTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      spacing: AppDimensions.sm,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onDepositTap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: const Text('Deposit'),
          ),
        ),
        IconActionBtn(
          icon: LucideIcons.pencil,
          isDark: isDark,
          onTap: onEditTap,
        ),
        IconActionBtn(
          icon: isLocked ? LucideIcons.lock : LucideIcons.unlock,
          isDark: isDark,
          onTap: onLockTap,
          isActive: isLocked,
        ),
        IconActionBtn(
          icon: LucideIcons.trash2,
          isDark: isDark,
          onTap: onDeleteTap,
        ),
      ],
    );
  }
}
