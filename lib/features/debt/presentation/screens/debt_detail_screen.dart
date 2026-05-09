import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_action_button.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

class DebtDetailModal extends StatefulWidget {
  final DebtEntity debt;
  final void Function(PaymentRecord) onPayment;

  const DebtDetailModal({
    super.key,
    required this.debt,
    required this.onPayment,
  });

  @override
  State<DebtDetailModal> createState() => _DebtDetailModalState();
}

class _DebtDetailModalState extends State<DebtDetailModal> {
  bool _paymentFormVisible = false;
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  static final _amountFmt = NumberFormat('#,##0.00');
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
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;
    final record = PaymentRecord(
      id: const Uuid().v4(),
      amount: amount,
      date: _paymentDate,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );
    Navigator.pop(context);
    widget.onPayment(record);
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    final isLent = debt.type == DebtType.lent;
    final amountColor =
        isLent ? AppColorsLight.success : AppColorsLight.error;
    final progress = debt.totalAmount > 0
        ? (debt.paidAmount / debt.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.sm,
        AppDimensions.md,
        AppDimensions.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ModalHandle(),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Text(debt.personName, style: AppTextStyles.h3),
                const SizedBox(width: AppDimensions.sm),
                const Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: AppColorsLight.textBody,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColorsLight.textBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                _TypeChip(type: debt.type),
                const SizedBox(width: AppDimensions.sm),
                StatusBadge(status: debt.status),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              '${_amountFmt.format(debt.remaining)} ETB',
              style: AppTextStyles.amountLg.copyWith(color: amountColor),
            ),
            Text(
              'remaining of ${_amountFmt.format(debt.totalAmount)} ETB',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: AppDimensions.sm),
            KiseProgressBar(progress: progress, height: 8),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Paid so far: ${_amountFmt.format(debt.paidAmount)} ETB',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColorsLight.textBody),
            ),
            const SizedBox(height: AppDimensions.lg),
            AnimatedCrossFade(
              crossFadeState: _paymentFormVisible
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              firstChild: SizedBox(
                width: double.infinity,
                child: KiseActionButton(
                  label: '+ Record Payment Received',
                  variant: KiseButtonVariant.outline,
                  onPressed: () =>
                      setState(() => _paymentFormVisible = true),
                ),
              ),
              secondChild: _PaymentForm(
                amountCtrl: _amountCtrl,
                dateCtrl: _dateCtrl,
                notesCtrl: _notesCtrl,
                onDateTap: _pickDate,
                onCancel: () =>
                    setState(() => _paymentFormVisible = false),
                onConfirm: _confirmPayment,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final DebtType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isLent = type == DebtType.lent;
    final color =
        isLent ? AppColorsLight.success : AppColorsLight.error;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isLent ? 'Lent' : 'Borrowed',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentForm extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onDateTap;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _PaymentForm({
    required this.amountCtrl,
    required this.dateCtrl,
    required this.notesCtrl,
    required this.onDateTap,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Record Payment Received', style: AppTextStyles.h3),
        const SizedBox(height: AppDimensions.md),
        KiseTextField(
          label: 'Amount ETB',
          hint: '0.00',
          controller: amountCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: dateCtrl,
            readOnly: true,
            onTap: onDateTap,
            decoration: InputDecoration(
              labelText: 'Date',
              prefixIcon: const Icon(LucideIcons.calendar),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ),
        KiseTextField(
          label: 'Notes (optional)',
          hint: 'e.g. half payment via Telebirr',
          controller: notesCtrl,
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(
              child: KiseActionButton(
                label: 'Cancel',
                variant: KiseButtonVariant.ghost,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: KiseActionButton(
                label: 'Confirm Payment',
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModalHandle extends StatelessWidget {
  const _ModalHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColorsLight.textHint.withValues(alpha:0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
