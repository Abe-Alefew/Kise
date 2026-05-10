import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_theme_ext.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

class StatusBadge extends StatelessWidget {
  final DebtStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DebtStatus.pending => (
          'pending',
          context.kiseBorrowedCardBg,
          context.kiseBorrowedCardIcon,
        ),
      DebtStatus.partial => (
          'partial',
          context.kiseLentCardBg,
          context.kiseLentCardIcon,
        ),
      DebtStatus.settled => (
          'settled',
          context.kiseSettledCardBg,
          context.kiseSettledCardIcon,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

Color statusFgColor(BuildContext context, DebtStatus s) => switch (s) {
      DebtStatus.pending => context.kiseBorrowedCardIcon,
      DebtStatus.partial => context.kiseLentCardIcon,
      DebtStatus.settled => context.kiseSettledCardIcon,
    };
