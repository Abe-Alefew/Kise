import 'package:flutter/material.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

const _pendingBg = Color(0xFFFFF3E0);
const _pendingFg = Color(0xFFE65100);
const _partialBg = Color(0xFFE3F2FD);
const _partialFg = Color(0xFF1565C0);
const _settledBg = Color(0xFFE8F5E9);
const _settledFg = Color(0xFF2E7D32);

class StatusBadge extends StatelessWidget {
  final DebtStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DebtStatus.pending => ('pending', _pendingBg, _pendingFg),
      DebtStatus.partial => ('partial', _partialBg, _partialFg),
      DebtStatus.settled => ('settled', _settledBg, _settledFg),
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
      DebtStatus.pending => _pendingFg,
      DebtStatus.partial => _partialFg,
      DebtStatus.settled => _settledFg,
    };
