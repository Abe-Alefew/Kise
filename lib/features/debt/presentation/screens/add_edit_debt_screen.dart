import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_action_button.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

class AddEditDebtModal extends StatefulWidget {
  final void Function(DebtEntity) onAdd;

  const AddEditDebtModal({super.key, required this.onAdd});

  @override
  State<AddEditDebtModal> createState() => _AddEditDebtModalState();
}

class _AddEditDebtModalState extends State<AddEditDebtModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DebtType _type = DebtType.lent;
  DateTime _selectedDate = DateTime.now();
  bool _showDetails = false;

  static final _dateFmt = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _dateFmt.format(_selectedDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
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
        AppDimensions.sm,
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
              const _ModalHandle(),
              const SizedBox(height: AppDimensions.sm),
              Text('New Debt Record', style: AppTextStyles.h3),
              const SizedBox(height: AppDimensions.md),
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: AppDimensions.md),
              KiseTextField(
                label: 'Person Name',
                hint: 'Enter name',
                controller: _nameCtrl,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              KiseTextField(
                label: 'Total Amount',
                hint: '0.00',
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                icon: LucideIcons.banknote,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
              _DateField(controller: _dateCtrl, onTap: _pickDate),
              const SizedBox(height: AppDimensions.xs),
              _AddDetailsToggle(
                value: _showDetails,
                onChanged: (v) => setState(() => _showDetails = v),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _showDetails
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppDimensions.sm),
                        child: KiseTextField(
                          label: 'Notes (optional)',
                          hint: 'Add any notes...',
                          controller: _notesCtrl,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: KiseActionButton(
                      label: 'Cancel',
                      variant: KiseButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: KiseActionButton(
                      label: 'Add Record',
                      onPressed: _submit,
                    ),
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

class _TypeSelector extends StatelessWidget {
  final DebtType selected;
  final ValueChanged<DebtType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DebtType.values.map((type) {
        final isSelected = type == selected;
        final label = type == DebtType.lent ? 'Lent' : 'Borrowed';
        final isFirst = type == DebtType.lent;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: isFirst ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColorsLight.primary
                    : AppColorsLight.secondaryBg,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColorsLight.textOnPrimary
                      : AppColorsLight.textBody,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(LucideIcons.calendar),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _AddDetailsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AddDetailsToggle(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Add Details', style: AppTextStyles.bodySm),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColorsLight.primary,
          activeTrackColor: AppColorsLight.primaryLight,
        ),
      ],
    );
  }
}
