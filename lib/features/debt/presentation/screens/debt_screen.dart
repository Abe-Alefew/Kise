import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_action_button.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/core/widgets/kise_pill_filter.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/screens/add_edit_debt_screen.dart';
import 'package:kise/features/debt/presentation/screens/debt_detail_screen.dart';
import 'package:kise/features/debt/presentation/widgets/debt_cart.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';
import 'package:kise/features/debt/presentation/widgets/toggle_actual_adjusted.dart';


// Screen


class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  bool _analyticsExpanded = false;
  bool _isActualView = true;
  String _selectedFilter = 'All';

  List<DebtEntity> _debts = [
    DebtEntity(
      id: '1',
      personName: 'Kirubel',
      type: DebtType.lent,
      totalAmount: 0.19,
      paidAmount: 0,
      date: DateTime(2026, 4, 16),
    ),
    DebtEntity(
      id: '2',
      personName: 'Abel',
      type: DebtType.borrowed,
      totalAmount: 2000.00,
      paidAmount: 1800.00,
      date: DateTime(2026, 4, 12),
    ),
    DebtEntity(
      id: '3',
      personName: 'Zeaman',
      type: DebtType.lent,
      totalAmount: 70000.00,
      paidAmount: 0,
      date: DateTime(2026, 4, 5),
    ),
    DebtEntity(
      id: '4',
      personName: 'Liya',
      type: DebtType.lent,
      totalAmount: 30000.00,
      paidAmount: 30000.00,
      date: DateTime(2026, 3, 30),
    ),
  ];

  // Computed helpers 

  double get _owedToMe => _debts
      .where((d) =>
          d.type == DebtType.lent && d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  double get _iOwe => _debts
      .where((d) =>
          d.type == DebtType.borrowed &&
          d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  double get _netPosition => _owedToMe - _iOwe;

  double get _recoveryRate {
    final totalAmount =
        _debts.fold(0.0, (s, d) => s + d.totalAmount);
    if (totalAmount == 0) return 0;
    final totalPaid =
        _debts.fold(0.0, (s, d) => s + d.paidAmount);
    return totalPaid / totalAmount;
  }

  List<DebtEntity> get _filteredDebts => switch (_selectedFilter) {
        'Active' => _debts
            .where((d) => d.status != DebtStatus.settled)
            .toList(),
        'Lent' =>
          _debts.where((d) => d.type == DebtType.lent).toList(),
        'Borrowed' =>
          _debts.where((d) => d.type == DebtType.borrowed).toList(),
        'Settled' =>
          _debts.where((d) => d.status == DebtStatus.settled).toList(),
        _ => List.of(_debts),
      };

  // Modal launchers 

  void _openAddModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditDebtModal(
        onAdd: (debt) => setState(() => _debts = [..._debts, debt]),
      ),
    );
  }

  void _openDetailModal(DebtEntity debt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtDetailModal(
        debt: debt,
        onPayment: (payment) {
          setState(() {
            final idx = _debts.indexWhere((d) => d.id == debt.id);
            if (idx >= 0) {
              _debts = List.of(_debts)
                ..[idx] = debt.copyWith(
                  paidAmount: debt.paidAmount + payment.amount,
                  payments: [...debt.payments, payment],
                );
            }
          });
        },
        onEdit: (updated) {
          setState(() {
            final idx = _debts.indexWhere((d) => d.id == debt.id);
            if (idx >= 0) _debts = List.of(_debts)..[idx] = updated;
          });
        },
        onDelete: () {
          setState(() =>
              _debts = _debts.where((d) => d.id != debt.id).toList());
        },
      ),
    );
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.md),
              _Header(onAdd: _openAddModal),
              const SizedBox(height: AppDimensions.md),
              _SummaryCards(
                owedToMe: _owedToMe,
                iOwe: _iOwe,
              ),
              const SizedBox(height: AppDimensions.sm),
              _NetPositionCard(
                netAmount: _netPosition,
                recoveryRate: _recoveryRate,
                isActual: _isActualView,
                onToggle: (v) =>
                    setState(() => _isActualView = v),
              ),
              const SizedBox(height: AppDimensions.sm),
              _AnalyticsAccordion(
                expanded: _analyticsExpanded,
                onToggle: () => setState(
                    () => _analyticsExpanded = !_analyticsExpanded),
                debts: _debts,
              ),
              const SizedBox(height: AppDimensions.sm),
              KisePillFilter(
                options: const ['All', 'Active', 'Lent', 'Borrowed', 'Settled'],
                selected: _selectedFilter,
                onSelected: (f) =>
                    setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: AppDimensions.sm),
              ..._filteredDebts.map(
                (d) => DebtCard(
                  debt: d,
                  onTap: () => _openDetailModal(d),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }
}


// Header
class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debts & Lending',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w900, 
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track lending & borrowing',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
        ),
        KiseActionButton(
          label: '+ Add',
          onPressed: onAdd,
          expanded: false,
          width: 88,
          height: AppDimensions.authButtonHeight,
          borderRadius: 14,
        ),
      ],
    );
  }
}


// Summary Cards


class _SummaryCards extends StatelessWidget {
  final double owedToMe;
  final double iOwe;

  const _SummaryCards({required this.owedToMe, required this.iOwe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Owed to me',
            amount: owedToMe,
            bgColor: AppColorsLight.lentCardBg,
            icon: LucideIcons.arrowUpRight,
            iconColor: AppColorsLight.lentCardIcon,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _SummaryCard(
            label: 'I owe',
            amount: iOwe,
            bgColor: AppColorsLight.borrowedCardBg,
            icon: LucideIcons.arrowDownLeft,
            iconColor: AppColorsLight.borrowedCardIcon,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.bgColor,
    required this.icon,
    required this.iconColor,
  });

  static final _fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return KiseCardHolder(
      backgroundColor: bgColor,
      borderColor: bgColor,
      showShadow: false,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: AppDimensions.xs),
              Text(label, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            _fmt.format(amount),
            style: AppTextStyles.h3.copyWith(
              color: AppColorsLight.textHeading,
            ),
          ),
          Text(
            'ETB',
            style: AppTextStyles.h3.copyWith(
              color: AppColorsLight.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}


// Net Position Card



class _NetPositionCard extends StatelessWidget {
  final double netAmount;
  final double recoveryRate;
  final bool isActual;
  final ValueChanged<bool> onToggle;

  const _NetPositionCard({
    required this.netAmount,
    required this.recoveryRate,
    required this.isActual,
    required this.onToggle,
  });

  static final _amtFmt = NumberFormat('+#,##0.00;-#,##0.00');
  static final _pctFmt = NumberFormat('##0');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isPositive = netAmount >= 0;
    final netColor = isPositive ? AppColorsLight.success : AppColorsLight.error;

    return KiseCardHolder(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left Side ──────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Net Position',
                  style: tt.bodyMedium?.copyWith( // Increased size
                    // fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4), // Tighter gap
                Text(
                  _amtFmt.format(netAmount),
                  style: AppTextStyles.h2.copyWith(color: netColor, height: 1.1),
                ),
                // 1. ETB moved below the amount
                Text(
                  'ETB',
                  style: AppTextStyles.h2.copyWith(color: netColor, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recovery rate: ${_pctFmt.format(recoveryRate * 100)}%',
                  style: tt.bodyMedium?.copyWith( // Increased size
                    // fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ── Right Side ──────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Balance view',
                style: tt.bodyMedium?.copyWith( // Increased size
                  // fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              ToggleActualAdjusted(
                isActual: isActual,
                onChanged: onToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Analytics Accordion

class _AnalyticsAccordion extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<DebtEntity> debts;

  const _AnalyticsAccordion({
    required this.expanded,
    required this.onToggle,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header card — fixed height, never changes ──
        KiseCardHolder(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm + 4,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.barChart2,
                    size: 18,
                    color: cs.onSurface,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Analytics',
                      style: AppTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Detached content — slides in below the header card ──
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 680),
            curve: Curves.easeInOutCubic,
            child: expanded
                ? _AnalyticsBody(debts: debts)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}


// Analytics Body


class _AnalyticsBody extends StatelessWidget {
  final List<DebtEntity> debts;

  const _AnalyticsBody({required this.debts});

  int get _pending =>
      debts.where((d) => d.status == DebtStatus.pending).length;
  int get _partial =>
      debts.where((d) => d.status == DebtStatus.partial).length;
  int get _settled =>
      debts.where((d) => d.status == DebtStatus.settled).length;

  double get _totalLent => debts
      .where((d) => d.type == DebtType.lent)
      .fold(0.0, (s, d) => s + d.totalAmount);

  double get _totalBorrowed => debts
      .where((d) => d.type == DebtType.borrowed)
      .fold(0.0, (s, d) => s + d.totalAmount);

  double get _owedToMe => debts
      .where((d) =>
          d.type == DebtType.lent && d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  double get _iOwe => debts
      .where((d) =>
          d.type == DebtType.borrowed &&
          d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  @override
  Widget build(BuildContext context) {
    final maxAmount = max(_totalLent, _totalBorrowed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.sm),

        // ── Status stat chips — directly on scaffold, no card bg ──
        _StatusStatsRow(
          pending: _pending,
          partial: _partial,
          settled: _settled,
        ),
        const SizedBox(height: AppDimensions.sm),

        // ── Status Breakdown card ──
        KiseCardHolder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Breakdown',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsLight.textHeading,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _DonutSection(
                pending: _pending,
                partial: _partial,
                settled: _settled,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // ── Lent vs Borrowed Overview card ──
        KiseCardHolder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lent vs Borrowed Overview',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsLight.textHeading,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _TableRow(
                label: 'Total Lent',
                amount: _totalLent,
                progress: maxAmount > 0 ? _totalLent / maxAmount : 0,
                barColor: AppColorsLight.lentCardIcon,
              ),
              const SizedBox(height: AppDimensions.xs),
              _TableRow(
                label: 'Total Borrowed',
                amount: _totalBorrowed,
                progress:
                    maxAmount > 0 ? _totalBorrowed / maxAmount : 0,
                barColor: AppColorsLight.borrowedCardIcon,
              ),
              const SizedBox(height: AppDimensions.xs),
              _TableRow(
                label: 'Outstanding (Owed to me)',
                amount: _owedToMe,
                progress:
                    _totalLent > 0 ? _owedToMe / _totalLent : 0,
                barColor: AppColorsLight.lentCardIcon,
              ),
              const SizedBox(height: AppDimensions.xs),
              _TableRow(
                label: 'Outstanding (I owe)',
                amount: _iOwe,
                progress:
                    _totalBorrowed > 0 ? _iOwe / _totalBorrowed : 0,
                barColor: AppColorsLight.borrowedCardIcon,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // ── Active Balances by Person card ──
        KiseCardHolder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Balances by Person',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsLight.textHeading,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              ...debts
                  .where((d) => d.status != DebtStatus.settled)
                  .map((d) => _PersonBalanceRow(debt: d)),
            ],
          ),
        ),
      ],
    );
  }
}


// Status Stats Row


class _StatusStatsRow extends StatelessWidget {
  final int pending;
  final int partial;
  final int settled;

  const _StatusStatsRow({
    required this.pending,
    required this.partial,
    required this.settled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          count: pending,
          label: 'Pending',
          icon: LucideIcons.clock,
          iconColor: AppColorsLight.borrowedCardIcon,
          bg: AppColorsLight.borrowedCardBg,
        ),
        const SizedBox(width: AppDimensions.sm),
        _StatBox(
          count: partial,
          label: 'Partial',
          icon: LucideIcons.gitBranch,
          iconColor: AppColorsLight.lentCardIcon,
          bg: AppColorsLight.lentCardBg,
        ),
        const SizedBox(width: AppDimensions.sm),
        _StatBox(
          count: settled,
          label: 'Settled',
          icon: LucideIcons.checkCircle,
          iconColor: AppColorsLight.settledCardIcon,
          bg: AppColorsLight.settledCardBg,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bg;

  const _StatBox({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.sm + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: AppDimensions.xs),
            Text(
              '$count',
              style: AppTextStyles.h2.copyWith(color: iconColor),
            ),
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                color: AppColorsLight.textHeading,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Donut Section


class _DonutSection extends StatelessWidget {
  final int pending;
  final int partial;
  final int settled;

  const _DonutSection({
    required this.pending,
    required this.partial,
    required this.settled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _DonutChartPainter(
              pending: pending,
              partial: partial,
              settled: settled,
              pendingColor: AppColorsLight.pendingChart,
              partialColor: AppColorsLight.partialChart,
              settledColor: AppColorsLight.settledChart,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: AppColorsLight.pendingChart,
                label: 'Pending',
                count: pending,
              ),
              const SizedBox(height: AppDimensions.xs),
              _LegendItem(
                color: AppColorsLight.partialChart,
                label: 'Partial',
                count: partial,
              ),
              const SizedBox(height: AppDimensions.xs),
              _LegendItem(
                color: AppColorsLight.settledChart,
                label: 'Settled',
                count: settled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySm),
        ),
        Text(
          '$count',
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColorsLight.textHeading,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int pending;
  final int partial;
  final int settled;
  final Color pendingColor;
  final Color partialColor;
  final Color settledColor;

  const _DonutChartPainter({
    required this.pending,
    required this.partial,
    required this.settled,
    required this.pendingColor,
    required this.partialColor,
    required this.settledColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (pending + partial + settled).toDouble();
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 18.0;
    const gapAngle = 0.07; // small gap matching Figma
    final rect = Rect.fromCircle(
        center: center, radius: radius - strokeWidth / 2);

    final segments = [
      (pending / total, pendingColor),
      (partial / total, partialColor),
      (settled / total, settledColor),
    ];

    var startAngle = -pi / 2;
    for (final (fraction, color) in segments) {
      if (fraction <= 0) continue;
      final sweepAngle = 2 * pi * fraction;
      canvas.drawArc(
        rect,
        startAngle + gapAngle / 2,
        sweepAngle - gapAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.pending != pending ||
      old.partial != partial ||
      old.settled != settled ||
      old.pendingColor != pendingColor ||
      old.partialColor != partialColor ||
      old.settledColor != settledColor;
}


// Lent vs Borrowed Table Row


class _TableRow extends StatelessWidget {
  final String label;
  final double amount;
  final double progress;
  final Color barColor;

  const _TableRow({
    required this.label,
    required this.amount,
    required this.progress,
    required this.barColor,
  });

  static final _fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColorsLight.textBody,
              ),
            ),
            Text(
              '${_fmt.format(amount)} ETB',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorsLight.textHeading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        KiseProgressBar(
          progress: progress.clamp(0.0, 1.0),
          height: 6,
          fillColor: barColor,
          trackColor: barColor.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}


// Active Balances — Person Row


class _PersonBalanceRow extends StatelessWidget {
  final DebtEntity debt;

  const _PersonBalanceRow({required this.debt});

  static final _fmt = NumberFormat('+#,##0.00;-#,##0.00');

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.lent;
    final balance = isLent ? debt.remaining : -debt.remaining;
    final amtColor =
        isLent ? AppColorsLight.lentCardIcon : AppColorsLight.error;
    final avatarBg =
        isLent ? AppColorsLight.lentCardBg : AppColorsLight.borrowedCardBg;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                debt.personInitial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: amtColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.personName,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColorsLight.textHeading,
                  ),
                ),
                Text(
                  isLent ? 'Lent' : 'Borrowed',
                  style: AppTextStyles.micro,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt.format(balance)} ETB',
                style: AppTextStyles.bodySm.copyWith(
                  color: amtColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StatusBadge(status: debt.status),
            ],
          ),
        ],
      ),
    );
  }
}
