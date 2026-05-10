import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

class AddEditDebtModal extends StatefulWidget {
  final void Function(DebtEntity) onAdd;

  const AddEditDebtModal({super.key, required this.onAdd});

  @override
  State<AddEditDebtModal> createState() => _AddEditDebtModalState();
}

class _AddEditDebtModalState extends State<AddEditDebtModal> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remainCtrl = TextEditingController();
  final _dateCtrl   = TextEditingController();
  final _notesCtrl  = TextEditingController();

  DebtType _type = DebtType.lent;
  DateTime _selectedDate = DateTime.now();

  static final _dateFmt = DateFormat('MM/dd/yyyy');
  static final _numFmt  = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _dateFmt.format(_selectedDate);
    _amountCtrl.addListener(_syncRemaining);
  }

  void _syncRemaining() {
    final val = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    _remainCtrl.text = val != null ? _numFmt.format(val) : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _remainCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = _dateFmt.format(picked);
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final debt = DebtEntity(
      id: const Uuid().v4(),
      personName: _nameCtrl.text.trim(),
      type: _type,
      totalAmount:
          double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
      paidAmount: 0,
      date: _selectedDate,
    );
    Navigator.pop(context);
    widget.onAdd(debt);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Debt Record', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColorsLight.secondaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 15,
                        color: AppColorsLight.textBody,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Type selector ───────────────────────────────
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Row 1: Person's Name ────────────────────────
              _LabeledField(
                label: "Person's Name",
                child: _ModalInput(
                  controller: _nameCtrl,
                  hint: 'Who?',
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Row 2: Total Amount + Remaining ────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Total Amount',
                      child: _ModalInput(
                        controller: _amountCtrl,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v.replaceAll(',', '')) ==
                              null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: _LabeledField(
                      label: 'Remaining',
                      child: _ModalInput(
                        controller: _remainCtrl,
                        hint: '',
                        readOnly: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Row 3: Date ─────────────────────────────────
              _LabeledField(
                label: 'Date',
                child: _ModalInput(
                  controller: _dateCtrl,
                  hint: _dateFmt.format(DateTime.now()),
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: LucideIcons.calendar,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Row 4: Notes (always visible) ───────────────
              _LabeledField(
                label: 'Notes (optional)',
                child: _ModalInput(
                  controller: _notesCtrl,
                  hint: 'Any details...',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Action buttons ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _CancelButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: _AddButton(onPressed: _submit),
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


// Type Selector


class _TypeSelector extends StatelessWidget {
  final DebtType selected;
  final ValueChanged<DebtType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'I Lent',
            isSelected: selected == DebtType.lent,
            selectedColor: AppColorsLight.lentCardIcon,
            onTap: () => onChanged(DebtType.lent),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _TypeButton(
            label: 'I Borrowed',
            isSelected: selected == DebtType.borrowed,
            selectedColor: AppColorsLight.borrowedCardIcon,
            onTap: () => onChanged(DebtType.borrowed),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColorsLight.secondaryBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? Colors.white : AppColorsLight.textBody,
          ),
        ),
      ),
    );
  }
}


// Label-above-field wrapper


class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColorsLight.textHeading,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        child,
      ],
    );
  }
}


// Input field — white bg, subtle border


class _ModalInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final TextInputType keyboardType;
  final IconData? suffixIcon;
  final VoidCallback? onTap;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ModalInput({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onTap,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final _borderColor =
        AppColorsLight.textHeading.withValues(alpha: 0.18);
    final _radius = BorderRadius.circular(AppDimensions.radiusSm);

    final defaultBorder = OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: _borderColor, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: _radius,
      borderSide:
          BorderSide(color: AppColorsLight.lentCardIcon, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColorsLight.error, width: 1.0),
    );

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType:
          maxLines > 1 ? TextInputType.multiline : keyboardType,
      maxLines: maxLines,
      onTap: onTap,
      validator: validator,
      style: AppTextStyles.bodySm.copyWith(
        color: AppColorsLight.textHeading,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySm.copyWith(
          color: AppColorsLight.textHint,
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: AppColorsLight.textBody)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm + 4,
          vertical: AppDimensions.sm + 2,
        ),
        border: defaultBorder,
        enabledBorder: defaultBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder.copyWith(
          borderSide: BorderSide(
              color: AppColorsLight.error, width: 1.5),
        ),
      ),
    );
  }
}


// Cancel button — outlined, black text, normal weight


class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.authButtonHeight + 6,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColorsLight.textHeading.withValues(alpha: 0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
        child: Text(
          'Cancel',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColorsLight.textHeading,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}


// Add Record button — gold fill, white text, normal weight


class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.authButtonHeight + 6,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
        child: Text(
          'Add Record',
          style: AppTextStyles.bodySm.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
