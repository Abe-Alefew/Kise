import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';

class GoalDepositForm extends StatefulWidget {
  final void Function(double amount, String source) onSave;
  final VoidCallback onCancel;

  const GoalDepositForm({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<GoalDepositForm> createState() => _GoalDepositFormState();
}

class _GoalDepositFormState extends State<GoalDepositForm> {
  final _amountController = TextEditingController();
  final _customSourceController = TextEditingController();
  String _selectedSource = 'CBE';
  final List<String> _sourceOptions = ['CBE', 'Telebirr', 'Bank of Abyssinia', 'Cash', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _customSourceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final source = _selectedSource == 'Other' ? _customSourceController.text : _selectedSource;
    widget.onSave(amount, source.isEmpty ? 'Unknown' : source);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KiseTextField(
                label: 'Amount',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSource,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 15),
                  ),
                  items: _sourceOptions.map((source) {
                    return DropdownMenuItem(
                      value: source,
                      child: Text(source, overflow: TextOverflow.ellipsis, style: isDark ? AppTextStylesDark.bodySm : AppTextStyles.bodySm,),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSource = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        if (_selectedSource == 'Other')
          KiseTextField(
            label: 'Custom Source',
            controller: _customSourceController,
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColorsLight.textHint, width: 1),
                  foregroundColor: isDark ? AppColorsDark.textBody : AppColorsLight.textBody,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Deposit'),
              ),
            ),
          ],
        )
      ],
    );
  }
}
