import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/settings/domain/settings_models.dart';
import 'package:kise/features/settings/presentation/state/settings_notifier.dart';
import 'package:kise/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _monthlyAllowanceController = TextEditingController();
  final TextEditingController _cycleStartDayController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  String _selectedAccountType = 'Bank';
  final List<String> _accountTypes = ['Bank', 'Mobile Money', 'Wallet', 'Other'];
  final List<String> _languages = ['English', 'Amharic'];

  bool _controllersHydrated = false;
  bool _isDeletingAccount = false;

  @override
  void dispose() {
    _monthlyAllowanceController.dispose();
    _cycleStartDayController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _hydrateControllers(SettingsBundle bundle) {
    if (_controllersHydrated) return;

    final amount = bundle.allowance.monthlyAmount;
    _monthlyAllowanceController.text = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    _cycleStartDayController.text = bundle.allowance.cycleStartDay.toString();
    _controllersHydrated = true;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _saveAllowance() async {
    final monthly = double.tryParse(_monthlyAllowanceController.text.trim());
    final cycleDay = int.tryParse(_cycleStartDayController.text.trim());

    if (monthly == null || monthly < 0) {
      _showSnack('Enter a valid monthly allowance', isError: true);
      return;
    }

    if (cycleDay == null || cycleDay < 1 || cycleDay > 28) {
      _showSnack('Cycle start day must be between 1 and 28', isError: true);
      return;
    }

    try {
      await ref.read(settingsNotifierProvider.notifier).saveAllowance(
            monthlyAmount: monthly,
            cycleStartDay: cycleDay,
          );
      setState(() => _controllersHydrated = false);
      _showSnack('Allowance settings saved!');
    } catch (e) {
      _showSnack(
        e is ApiException ? e.message : 'Could not save allowance settings',
        isError: true,
      );
    }
  }

  Future<void> _addAccount() async {
    final name = _accountNameController.text.trim();
    if (name.isEmpty) return;

    try {
      await ref.read(settingsNotifierProvider.notifier).addAccount(
            name: name,
            type: _selectedAccountType,
          );
      _accountNameController.clear();
      _showSnack('Account added');
    } catch (e) {
      _showSnack(
        e is ApiException ? e.message : 'Could not add account',
        isError: true,
      );
    }
  }

  Future<void> _removeAccount(String accountId) async {
    try {
      await ref.read(settingsNotifierProvider.notifier).removeAccount(accountId);
      _showSnack('Account removed');
    } catch (e) {
      _showSnack(
        e is ApiException ? e.message : 'Could not remove account',
        isError: true,
      );
    }
  }

  Future<void> _updateLanguage(String language) async {
    try {
      await ref.read(settingsNotifierProvider.notifier).updateLanguage(language);
    } catch (e) {
      _showSnack(
        e is ApiException ? e.message : 'Could not update language',
        isError: true,
      );
    }
  }

  Future<void> _updateTheme(ThemeMode mode) async {
    try {
      await ref.read(settingsNotifierProvider.notifier).updateThemeMode(mode);
    } catch (e) {
      _showSnack(
        e is ApiException ? e.message : 'Could not update theme',
        isError: true,
      );
    }
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
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
        actionsPadding: const EdgeInsets.fromLTRB(
          AppDimensions.md,
          0,
          AppDimensions.md,
          AppDimensions.md,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isDeletingAccount
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: _isDeletingAccount
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          setState(() => _isDeletingAccount = true);
                          try {
                            await ref
                                .read(settingsNotifierProvider.notifier)
                                .deleteUserAccount();
                          } catch (e) {
                            if (mounted) {
                              _showSnack(
                                e is ApiException
                                    ? e.message
                                    : 'Could not delete account',
                                isError: true,
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isDeletingAccount = false);
                            }
                          }
                        },
                  child: _isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final flags = ref.watch(settingsUiFlagsProvider);
    final authUser = ref.watch(authStateProvider)?.user;

    ref.listen(settingsNotifierProvider, (previous, next) {
      next.whenData((bundle) {
        if (mounted) {
          _hydrateControllers(bundle);
        }
      });
    });

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final bool useSystemDefault = themeMode == ThemeMode.system;

    final bundle = settingsAsync.value;
    final accounts = bundle?.accounts ?? const <PaymentAccountSettings>[];
    final selectedLanguage =
        bundle?.preferences.preferredLanguage ?? 'English';

    if (bundle == null) {
      if (settingsAsync.isLoading) {
        return const Scaffold(
          body: SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settingsAsync.error is ApiException
                        ? (settingsAsync.error! as ApiException).message
                        : 'Could not load settings',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(settingsNotifierProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
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
                  SettingsProfileTile(
                    name: authUser?.fullName ?? '—',
                    email: authUser?.email ?? '—',
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  SettingsSectionHeader(
                    title: 'Allowance Setup',
                    icon: LucideIcons.wallet,
                  ),
                  SettingsCard(
                    child: AllowanceSetupCard(
                      monthlyController: _monthlyAllowanceController,
                      cycleDayController: _cycleStartDayController,
                      onSave: flags.isSavingAllowance ? () {} : _saveAllowance,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  SettingsSectionHeader(
                    title: 'Banks & Payment Accounts',
                    subtitle:
                        'Add your banks, wallets, or mobile money accounts.',
                    icon: LucideIcons.creditCard,
                  ),
                  SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (accounts.isNotEmpty) ...[
                          ...accounts.asMap().entries.map(
                            (e) => Column(
                              children: [
                                BankAccountRow(
                                  accountName: e.value.name,
                                  accountType: e.value.type,
                                  onDelete: flags.deletingAccountId == e.value.id
                                      ? null
                                      : () => _removeAccount(e.value.id),
                                ),
                                if (e.key < accounts.length - 1)
                                  const Divider(height: 1),
                              ],
                            ),
                          ),
                          const Divider(height: AppDimensions.lg),
                        ],
                        AddAccountForm(
                          nameController: _accountNameController,
                          selectedType: _selectedAccountType,
                          accountTypes: _accountTypes,
                          onTypeChanged: (v) {
                            if (!flags.isAddingAccount && v != null) {
                              setState(() => _selectedAccountType = v);
                            }
                          },
                          onAdd: flags.isAddingAccount ? () {} : _addAccount,
                        ),
                        if (flags.isAddingAccount)
                          const Padding(
                            padding: EdgeInsets.only(top: AppDimensions.sm),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  SettingsSectionHeader(
                    title: 'Appearance',
                    subtitle: 'Personalize your interface theme.',
                    icon: LucideIcons.sun,
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.monitor,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Text(
                                  'Use system default',
                                  style: isDark
                                      ? AppTextStylesDark.bodyLg
                                      : AppTextStyles.bodyLg,
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: useSystemDefault,
                              activeThumbColor:
                                  Theme.of(context).colorScheme.primary,
                              onChanged: flags.isUpdatingPreferences
                                  ? null
                                  : (val) {
                                      _updateTheme(
                                        val
                                            ? ThemeMode.system
                                            : (isDark
                                                ? ThemeMode.dark
                                                : ThemeMode.light),
                                      );
                                    },
                            ),
                          ],
                        ),
                        const Divider(height: AppDimensions.md),
                        Opacity(
                          opacity: useSystemDefault ? 0.5 : 1.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDark ? LucideIcons.moon : LucideIcons.sun,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                activeThumbColor:
                                    Theme.of(context).colorScheme.primary,
                                onChanged: useSystemDefault ||
                                        flags.isUpdatingPreferences
                                    ? null
                                    : (val) {
                                        _updateTheme(
                                          val ? ThemeMode.dark : ThemeMode.light,
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  SettingsSectionHeader(
                    title: 'Language',
                    subtitle: 'Choose your preferred language.',
                    icon: LucideIcons.globe,
                  ),
                  SettingsCard(
                    child: Column(
                      children: _languages.asMap().entries.map(
                        (e) => Column(
                          children: [
                            SettingsOptionRow(
                              label: e.value,
                              isSelected: selectedLanguage == e.value,
                              onTap: flags.isUpdatingPreferences
                                  ? () {}
                                  : () => _updateLanguage(e.value),
                            ),
                            if (e.key < _languages.length - 1)
                              const Divider(height: 1),
                          ],
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  WarningActionButton(
                    label: 'Log Out',
                    leadingIcon: LucideIcons.logOut,
                    onPressed: _showLogoutDialog,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  WarningActionButton(
                    label: 'Delete Account',
                    leadingIcon: LucideIcons.trash2,
                    onPressed: _showDeleteAccountDialog,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Center(
                    child: Text(
                      'Kise (ኪሴ) v1.0 — Built for students',
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
