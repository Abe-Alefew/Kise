import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

class StatusBadge extends StatelessWidget {
  final DebtStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DebtStatus.pending => (
          'pending',
          AppColorsLight.borrowedCardBg,
          AppColorsLight.borrowedCardIcon,
        ),
      DebtStatus.partial => (
          'partial',
          AppColorsLight.lentCardBg,
          AppColorsLight.lentCardIcon,
        ),
      DebtStatus.settled => (
          'settled',
          AppColorsLight.settledCardBg,
          AppColorsLight.settledCardIcon,
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

Color statusFgColor(DebtStatus s) => switch (s) {
      DebtStatus.pending => AppColorsLight.borrowedCardIcon,
      DebtStatus.partial => AppColorsLight.lentCardIcon,
      DebtStatus.settled => AppColorsLight.settledCardIcon,
    };
