import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/app_theme_ext.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/screens/add_edit_debt_screen.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

class DebtDetailModal extends StatefulWidget {
  final DebtEntity debt;
  final void Function(PaymentRecord) onPayment;
  final void Function(DebtEntity) onEdit;
  final VoidCallback onDelete;

  const DebtDetailModal({
    super.key,
    required this.debt,
    required this.onPayment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DebtDetailModal> createState() => _DebtDetailModalState();
}

class _DebtDetailModalState extends State<DebtDetailModal> {
  bool _paymentFormVisible = false;

  final _amountCtrl = TextEditingController(text: '0.00');
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  static final _amtFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _dateFmt.format(_paymentDate);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        _dateCtrl.text = _dateFmt.format(picked);
      });
    }
  }

  void _confirmPayment() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;
    final record = PaymentRecord(
      id: const Uuid().v4(),
      amount: amount,
      date: _paymentDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    Navigator.pop(context);
    widget.onPayment(record);
  }

  void _openEditModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditDebtModal(
        existingDebt: widget.debt,
        onAdd: (_) {},
        onEdit: (updated) {
          Navigator.pop(context);
          widget.onEdit(updated);
        },
        onDelete: () {
          Navigator.pop(context);
          widget.onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    final isLent = debt.type == DebtType.lent;
    final progress = debt.totalAmount > 0
        ? (debt.paidAmount / debt.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).round();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md + bottomInset,
      ),
      decoration: BoxDecoration(
        color: context.kiseCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon · name + pencil · close ──────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeIcon(isLent: isLent),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            debt.personName,
                            style: AppTextStyles.h3.copyWith(
                              color: context.kiseTextHeading,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.xs + 2),
                          GestureDetector(
                            onTap: _openEditModal,
                            child: Icon(
                              LucideIcons.pencil,
                              size: 15,
                              color: context.kiseTextBody,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${isLent ? 'You lent' : 'You borrowed'}  ·  '
                        '${DateFormat('MMM d, yyyy').format(debt.date)}',
                        style: AppTextStyles.micro.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.kiseTextHeading.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.kiseSecondaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 15,
                      color: context.kiseTextBody,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Financial status: amount · badge ───────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_amtFmt.format(debt.remaining)} ETB',
                        style: AppTextStyles.amountLg.copyWith(
                          color: context.kiseTextHeading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'remaining of ${_amtFmt.format(debt.totalAmount)} ETB',
                        style: AppTextStyles.bodySm.copyWith(
                          color: context.kiseTextHeading.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                StatusBadge(status: debt.status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),

            // ── Progress ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid so far',
                  style: AppTextStyles.bodySm.copyWith(
                    color: context.kiseTextHeading.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  '$pct% (${_amtFmt.format(debt.paidAmount)} ETB)',
                  style: AppTextStyles.bodySm.copyWith(
                    color: context.kiseTextHeading.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            KiseProgressBar(
              progress: progress,
              height: 6,
              fillColor: context.kiseSuccess,
              trackColor: context.kiseSuccess.withValues(alpha: 0.12),
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Payment button / expandable form ───────────────
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: _paymentFormVisible
                    ? _PaymentFormCard(
                        amountCtrl: _amountCtrl,
                        dateCtrl: _dateCtrl,
                        notesCtrl: _notesCtrl,
                        onDateTap: _pickDate,
                        onCancel: () =>
                            setState(() => _paymentFormVisible = false),
                        onConfirm: _confirmPayment,
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _paymentFormVisible = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.kisePrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                          ),
                          child: Text(
                            '+ Record Payment Received',
                            style: AppTextStyles.bodySm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Type icon — matches DebtCard

class _TypeIcon extends StatelessWidget {
  final bool isLent;
  const _TypeIcon({required this.isLent});

  @override
  Widget build(BuildContext context) {
    final bg = isLent ? context.kiseLentCardBg : context.kiseBorrowedCardBg;
    final iconColor = isLent ? context.kiseLentCardIcon : context.kiseBorrowedCardIcon;
    final icon = isLent ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm + 2),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

// Payment Form Card

class _PaymentFormCard extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onDateTap;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _PaymentFormCard({
    required this.amountCtrl,
    required this.dateCtrl,
    required this.notesCtrl,
    required this.onDateTap,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return KiseCardHolder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Payment Received',
            style: AppTextStyles.h3.copyWith(color: context.kiseTextHeading),
          ),
          const SizedBox(height: AppDimensions.md),

          // Amount (ETB) + Date row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormLabel(
                  label: 'Amount (ETB)',
                  child: _SpinnerInput(controller: amountCtrl),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _FormLabel(
                  label: 'Date',
                  child: _PaymentInput(
                    controller: dateCtrl,
                    hint: '',
                    readOnly: true,
                    onTap: onDateTap,
                    suffixIcon: LucideIcons.calendar,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Note (optional)
          _FormLabel(
            label: 'Note (optional)',
            child: _PaymentInput(
              controller: notesCtrl,
              hint: 'e.g. half payment via Telebirr',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Cancel + Confirm
          Row(
            children: [
              Expanded(child: _FormCancelBtn(onPressed: onCancel)),
              const SizedBox(width: AppDimensions.sm),
              Expanded(child: _FormConfirmBtn(onPressed: onConfirm)),
            ],
          ),
        ],
      ),
    );
  }
}

// Label above field

class _FormLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: context.kiseTextHeading,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        child,
      ],
    );
  }
}

// Shared input border helper

OutlineInputBorder _inputBorder({double width = 1.0, required Color color}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );

// Spinner input (amount with up/down chevrons)

class _SpinnerInput extends StatelessWidget {
  final TextEditingController controller;
  const _SpinnerInput({required this.controller});

  void _adjust(double delta) {
    final val = double.tryParse(controller.text.replaceAll(',', '')) ?? 0;
    final next = (val + delta).clamp(0.0, double.infinity);
    controller.text = next.toStringAsFixed(2);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.kiseTextHeading.withValues(alpha: 0.18);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.bodySm.copyWith(color: context.kiseTextHeading),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: AppTextStyles.bodySm.copyWith(color: context.kiseTextHint),
        filled: true,
        fillColor: context.kiseCard,
        border: _inputBorder(color: borderColor),
        enabledBorder: _inputBorder(color: borderColor),
        focusedBorder: _inputBorder(width: 1.5, color: context.kiseLentCardIcon),
        errorBorder: _inputBorder(color: context.kiseError),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm + 4,
          vertical: AppDimensions.sm + 2,
        ),
        suffixIcon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _adjust(1),
              child: Icon(
                LucideIcons.chevronUp,
                size: 13,
                color: context.kiseTextBody,
              ),
            ),
            GestureDetector(
              onTap: () => _adjust(-1),
              child: Icon(
                LucideIcons.chevronDown,
                size: 13,
                color: context.kiseTextBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Plain input (date / notes)

class _PaymentInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final int maxLines;

  const _PaymentInput({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = context.kiseTextHeading.withValues(alpha: 0.18);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      maxLines: maxLines,
      onTap: onTap,
      style: AppTextStyles.bodySm.copyWith(color: context.kiseTextHeading),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySm.copyWith(color: context.kiseTextHint),
        filled: true,
        fillColor: context.kiseCard,
        border: _inputBorder(color: borderColor),
        enabledBorder: _inputBorder(color: borderColor),
        focusedBorder: _inputBorder(width: 1.5, color: context.kiseLentCardIcon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm + 4,
          vertical: AppDimensions.sm + 2,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: context.kiseTextBody)
            : null,
      ),
    );
  }
}

// Cancel button

class _FormCancelBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _FormCancelBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.authButtonHeight + 6,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: context.kiseTextHeading.withValues(alpha: 0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
        child: Text(
          'Cancel',
          style: AppTextStyles.bodySm.copyWith(
            color: context.kiseTextHeading,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// Confirm Payment button

class _FormConfirmBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _FormConfirmBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.authButtonHeight + 6,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.kisePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
        child: Text(
          'Confirm Payment',
          style: AppTextStyles.bodySm.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
