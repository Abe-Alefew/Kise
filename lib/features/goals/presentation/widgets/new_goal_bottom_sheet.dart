import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';

class NewGoalBottomSheet extends StatefulWidget {
  final void Function(
    String title,
    double targetAmount,
    double currentAmount,
    String deadline,
    String period,
    String note,
  ) onSave;
  
  const NewGoalBottomSheet({super.key, required this.onSave});

  @override
  State<NewGoalBottomSheet> createState() => _NewGoalBottomSheetState();
}

class _NewGoalBottomSheetState extends State<NewGoalBottomSheet> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedPeriod = 'monthly';
  final List<String> _periodOptions = ['daily', 'weekly', 'monthly', 'yearly', 'one-time'];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _deadlineController.dispose();
    _noteController.dispose();
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
    final title = _titleController.text.trim();
    if (title.isEmpty) return; // Optional simple boundary-check

    final target = double.tryParse(_targetController.text) ?? 0.0;
    final saved = double.tryParse(_savedController.text) ?? 0.0;
    final deadline = _deadlineController.text;
    final note = _noteController.text;

    widget.onSave(title, target, saved, deadline, _selectedPeriod, note);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Goal',
              style: isDark ? AppTextStylesDark.h3.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.lg),
            
            KiseTextField(
              label: 'Goal Name',
              hint: 'e.g. Save for textbooks',
              controller: _titleController,
            ),
            
            Row(
              children: [
                Expanded(
                  child: KiseTextField(
                    label: 'Target Amount',
                    hint: '0.00',
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: KiseTextField(
                    label: 'Saved so far',
                    hint: '0.00',
                    controller: _savedController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 15),
                      ),
                      items: _periodOptions.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period, style: isDark ? AppTextStylesDark.bodySm : AppTextStyles.bodySm),
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
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _deadlineController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        hintText: 'mm/dd/yyyy',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.md),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD69A33), 
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Goal'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
