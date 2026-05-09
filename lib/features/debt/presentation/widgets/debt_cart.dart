import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.debt, required this.onTap});

  static final _amountFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.lent;
    final amountColor =
        isLent ? AppColorsLight.success : AppColorsLight.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: KiseCardHolder(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(initial: debt.personInitial, isLent: isLent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            debt.personName,
                            style:
                                AppTextStyles.h3.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: debt.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Recovered: ${_dateFmt.format(debt.date)}',
                      style: AppTextStyles.micro
                          .copyWith(color: AppColorsLight.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isLent ? '+' : '-'}${_amountFmt.format(debt.remaining)} ETB',
                    style: AppTextStyles.bodySm.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of ${_amountFmt.format(debt.totalAmount)} ETB',
                    style: AppTextStyles.micro,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final bool isLent;

  const _Avatar({required this.initial, required this.isLent});

  @override
  Widget build(BuildContext context) {
    final color =
        isLent ? AppColorsLight.success : AppColorsLight.error;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
