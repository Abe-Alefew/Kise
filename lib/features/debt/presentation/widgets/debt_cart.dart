import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/app_theme_ext.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.debt, required this.onTap});

  static final _amtFmt  = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.lent;

    // For settled cards remaining = 0, show totalAmount as main figure instead.
    final mainAmount = debt.status == DebtStatus.settled
        ? debt.totalAmount
        : debt.remaining;

    final subLabel =
        '${isLent ? 'You lent' : 'You borrowed'} · ${_dateFmt.format(debt.date)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm + 2),
      child: GestureDetector(
        onTap: onTap,
        child: KiseCardHolder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Leading: tint-bg square + coloured arrow icon ──
              _TypeIcon(isLent: isLent),
              const SizedBox(width: AppDimensions.sm + 4),

              // ── Content column ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: name  |  status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            debt.personName,
                            style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.kiseTextHeading,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: debt.status),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Row 2: "You lent · Apr 16, 2026"
                    Text(
                      subLabel,
                      style: AppTextStyles.micro.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.kiseTextHeading.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: big remaining amount  |  "of total ETB"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_amtFmt.format(mainAmount)} ETB',
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.kiseTextHeading,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'of ${_amtFmt.format(debt.totalAmount)} ETB',
                          style: AppTextStyles.label.copyWith(
                            color: context.kiseTextHeading.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final bool isLent;
  const _TypeIcon({required this.isLent});

  @override
  Widget build(BuildContext context) {
    final bg = isLent
        ? context.kiseLentCardBg
        : context.kiseBorrowedCardBg;
    final iconColor = isLent
        ? context.kiseLentCardIcon
        : context.kiseBorrowedCardIcon;
    final icon =
        isLent ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusSm + 2),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
