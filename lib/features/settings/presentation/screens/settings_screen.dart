import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/kise_action_button.dart';
import 'package:kise/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Allowance ──────────────────────────────────────────────
  final TextEditingController _monthlyAllowanceController = TextEditingController(text: '3000');
  final TextEditingController _cycleStartDayController = TextEditingController(text: '1');

  // ── Accounts ───────────────────────────────────────────────
  final List<Map<String, String>> _accounts = [
    {'name': 'CBE', 'type': 'Bank'},
    {'name': 'Telebirr', 'type': 'Mobile Money'},
  ];
  final TextEditingController _accountNameController = TextEditingController();
  String _selectedAccountType = 'Bank';
  final List<String> _accountTypes = ['Bank', 'Mobile Money', 'Wallet', 'Other'];

  // ── Language ───────────────────────────────────────────────
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Amharic'];

  @override
  void dispose() {
    _monthlyAllowanceController.dispose();
    _cycleStartDayController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────
  void _saveAllowance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allowance settings saved!')),
    );
  }

  void _addAccount() {
    final name = _accountNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _accounts.add({'name': name, 'type': _selectedAccountType});
      _accountNameController.clear();
    });
  }

  void _removeAccount(int index) {
    setState(() => _accounts.removeAt(index));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: trigger logout logic
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data will be erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: trigger delete account logic
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Page Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.md,
                  AppDimensions.lg,
                  AppDimensions.md,
                  AppDimensions.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: isDark ? AppTextStylesDark.h2 : AppTextStyles.h2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your preferences',
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark
                            ? AppColorsDark.textHint
                            : AppColorsLight.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Profile Tile ─────────────────────────
                  const SettingsProfileTile(
                    name: 'Betsinat Wendwesen',
                    email: 'betsinat39@gmail.com',
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // ── Allowance Setup ──────────────────────
                  SettingsSectionHeader(
                    title: 'Allowance Setup',
                    icon: LucideIcons.wallet,
                  ),
                  SettingsCard(
                    child: AllowanceSetupCard(
                      monthlyController: _monthlyAllowanceController,
                      cycleDayController: _cycleStartDayController,
                      onSave: _saveAllowance,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // ── Banks & Payment Accounts ─────────────
                  SettingsSectionHeader(
                    title: 'Banks & Payment Accounts',
                    subtitle: 'Add your banks, wallets, or mobile money accounts.',
                    icon: LucideIcons.creditCard,
                  ),
                  SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Existing accounts
                        if (_accounts.isNotEmpty) ...[
                          ..._accounts.asMap().entries.map(
                            (e) => Column(
                              children: [
                                BankAccountRow(
                                  accountName: e.value['name']!,
                                  accountType: e.value['type']!,
                                  onDelete: () => _removeAccount(e.key),
                                ),
                                if (e.key < _accounts.length - 1)
                                  const Divider(height: 1),
                              ],
                            ),
                          ),
                          const Divider(height: AppDimensions.lg),
                        ],
                        // Add account form
                        AddAccountForm(
                          nameController: _accountNameController,
                          selectedType: _selectedAccountType,
                          accountTypes: _accountTypes,
                          onTypeChanged: (v) =>
                              setState(() => _selectedAccountType = v!),
                          onAdd: _addAccount,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // ── Dark Mode ────────────────────────────
                  SettingsSectionHeader(
                    title: 'Dark Mode',
                    subtitle: 'Switch between light and dark mode.',
                    icon: LucideIcons.sun,
                  ),
                  SettingsCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDark ? LucideIcons.moon : LucideIcons.sun,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Text(
                              isDark ? 'Dark Mode' : 'Light Mode',
                              style: isDark
                                  ? AppTextStylesDark.bodyLg
                                  : AppTextStyles.bodyLg,
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isDark,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            // Theme toggling is managed at the app level.
                            // Notify via callback or provider — placeholder:
                            // ref.read(themeProvider.notifier).toggle();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // ── Language ─────────────────────────────
                  SettingsSectionHeader(
                    title: 'Language',
                    subtitle: 'Choose your preferred language.',
                    icon: LucideIcons.globe,
                  ),
                  SettingsCard(
                    child: Column(
                      children: _languages
                          .asMap()
                          .entries
                          .map(
                            (e) => Column(
                              children: [
                                SettingsOptionRow(
                                  label: e.value,
                                  isSelected: _selectedLanguage == e.value,
                                  onTap: () => setState(
                                    () => _selectedLanguage = e.value,
                                  ),
                                ),
                                if (e.key < _languages.length - 1)
                                  const Divider(height: 1),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.xl),

                  // ── Log Out ──────────────────────────────
                  KiseActionButton(
                    label: 'Log Out',
                    leadingIcon: LucideIcons.logOut,
                    variant: KiseButtonVariant.outline,
                    textColor: Theme.of(context).colorScheme.error,
                    onPressed: _showLogoutDialog,
                  ),

                  const SizedBox(height: AppDimensions.md),

                  // ── Delete Account ───────────────────────
                  KiseActionButton(
                    label: 'Delete Account',
                    leadingIcon: LucideIcons.trash2,
                    variant: KiseButtonVariant.ghost,
                    textColor: Theme.of(context).colorScheme.error,
                    onPressed: _showDeleteAccountDialog,
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // ── Footer ───────────────────────────────
                  Center(
                    child: Text(
                      'Kise v1.0 — Built for students',
                      style: AppTextStyles.micro.copyWith(
                        color: isDark
                            ? AppColorsDark.textHint
                            : AppColorsLight.textHint,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
