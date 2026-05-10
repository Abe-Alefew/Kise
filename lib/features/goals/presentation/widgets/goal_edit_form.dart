import 'package:flutter/material.dart';
// Note: We use a simple manual formatter to match 'Mon Feb 25 2026' to avoid adding intl package dependency if not already there.
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';

class GoalEditForm extends StatefulWidget {
  final String initialTitle;
  final double initialTarget;
  final String initialDeadline;
  final String initialPeriod;
  final void Function(String title, double targetAmount, String deadline, String period) onSave;
  final VoidCallback onCancel;

  const GoalEditForm({
    super.key,
    required this.initialTitle,
    required this.initialTarget,
    required this.initialDeadline,
    required this.initialPeriod,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<GoalEditForm> createState() => _GoalEditFormState();
}

class _GoalEditFormState extends State<GoalEditForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _deadlineController;
  
  String _selectedPeriod = 'Monthly';
  final List<String> _periodOptions = ['Daily', 'Weekly', 'Monthly', 'Yearly', 'One-time'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _targetController = TextEditingController(text: widget.initialTarget.toStringAsFixed(2));
    _deadlineController = TextEditingController(text: widget.initialDeadline);
    
    // Normalize period if it differs slightly from options
    final matchedPeriod = _periodOptions.where((p) => p.toLowerCase() == widget.initialPeriod.toLowerCase()).firstOrNull;
    if (matchedPeriod != null) {
      _selectedPeriod = matchedPeriod;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday $month ${date.day} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text = 'Due ${_formatDate(picked)}';
      });
    }
  }

  void _handleSave() {
    final title = _titleController.text;
    final target = double.tryParse(_targetController.text) ?? widget.initialTarget;
    final deadline = _deadlineController.text;
    widget.onSave(title, target, deadline, _selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KiseTextField(
                label: 'New Title',
                controller: _titleController,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _deadlineController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'New deadline',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KiseTextField(
                label: 'New Target',
                controller: _targetController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'New Period',
                    contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 15),
                  ),
                  items: _periodOptions.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPeriod = val);
                    }
                  },
                ),
              ),
            ),
          ],
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
                child: const Text('Save'),
              ),
            ),
          ],
        )
      ],
    );
  }
}
