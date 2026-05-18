import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Profile header tile shown at the top of the Settings page.
class SettingsProfileTile extends StatelessWidget {
  final String name;
  final String email;

  const SettingsProfileTile({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColorsLight.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColorsDark.border.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              size: 24,
              color: primary,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: (isDark ? AppTextStylesDark.h3 : AppTextStyles.h3)
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? AppColorsDark.textHint
                        : AppColorsLight.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Allowance setup section: monthly amount + cycle start day.
class AllowanceSetupCard extends StatelessWidget {
  final TextEditingController monthlyController;
  final TextEditingController cycleDayController;
  final VoidCallback onSave;

  const AllowanceSetupCard({
    super.key,
    required this.monthlyController,
    required this.cycleDayController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? AppColorsDark.textHint : AppColorsLight.textHint;

    InputDecoration _fieldDecor(String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTextStyles.bodySm.copyWith(color: labelColor),
          hintStyle: AppTextStyles.bodySm.copyWith(
            color: isDark
                ? AppColorsDark.textHint
                : AppColorsLight.textHint,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: monthlyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecor('Monthly Allowance (ETB)', 'e.g. 3000'),
        ),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: cycleDayController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecor('Cycle Start Day (1–31)', '1'),
        ),
        const SizedBox(height: AppDimensions.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            child: const Text('Save Settings'),
          ),
        ),
      ],
    );
  }
}

/// A single bank / payment account row.
class BankAccountRow extends StatelessWidget {
  final String accountName;
  final String accountType;
  final VoidCallback? onDelete;

  const BankAccountRow({
    super.key,
    required this.accountName,
    required this.accountType,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: (isDark
                          ? AppTextStylesDark.bodyLg
                          : AppTextStyles.bodyLg)
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  accountType,
                  style: AppTextStyles.micro.copyWith(
                    color: isDark
                        ? AppColorsDark.textHint
                        : AppColorsLight.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColorsLight.error,
              ),
              onPressed: onDelete,
              splashRadius: 20,
              tooltip: 'Remove account',
            ),
        ],
      ),
    );
  }
}

/// Form to add a new bank / payment account.
class AddAccountForm extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedType;
  final List<String> accountTypes;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onAdd;

  const AddAccountForm({
    super.key,
    required this.nameController,
    required this.selectedType,
    required this.accountTypes,
    required this.onTypeChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color hintColor =
        isDark ? AppColorsDark.textHint : AppColorsLight.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Account name',
            hintText: 'e.g. CBE, Telebirr',
            labelStyle: AppTextStyles.bodySm.copyWith(color: hintColor),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        DropdownButtonFormField<String>(
          value: selectedType,
          decoration: InputDecoration(
            labelText: 'Type',
            labelStyle: AppTextStyles.bodySm.copyWith(color: hintColor),
          ),
          dropdownColor:
              isDark ? AppColorsDark.card : AppColorsLight.card,
          style: (isDark ? AppTextStylesDark.bodySm : AppTextStyles.bodySm)
              .copyWith(fontSize: 14),
          items: accountTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: AppDimensions.md),
        Center(
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Account'),
          ),
        ),
      ],
    );
  }
}
