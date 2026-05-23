import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/home/presentation/providers/home_dashboard_notifier.dart';
import 'package:kise/features/settings/data/settings_dto.dart';
import 'package:kise/features/settings/data/settings_repository.dart';
import 'package:kise/features/settings/domain/settings_models.dart';

@immutable
class SettingsUiFlags {
  final bool isSavingAllowance;
  final bool isAddingAccount;
  final String? deletingAccountId;
  final bool isUpdatingPreferences;

  const SettingsUiFlags({
    this.isSavingAllowance = false,
    this.isAddingAccount = false,
    this.deletingAccountId,
    this.isUpdatingPreferences = false,
  });

  SettingsUiFlags copyWith({
    bool? isSavingAllowance,
    bool? isAddingAccount,
    String? deletingAccountId,
    bool clearDeletingAccountId = false,
    bool? isUpdatingPreferences,
  }) {
    return SettingsUiFlags(
      isSavingAllowance: isSavingAllowance ?? this.isSavingAllowance,
      isAddingAccount: isAddingAccount ?? this.isAddingAccount,
      deletingAccountId: clearDeletingAccountId
          ? null
          : (deletingAccountId ?? this.deletingAccountId),
      isUpdatingPreferences:
          isUpdatingPreferences ?? this.isUpdatingPreferences,
    );
  }
}

class SettingsUiFlagsNotifier extends Notifier<SettingsUiFlags> {
  @override
  SettingsUiFlags build() => const SettingsUiFlags();
}

final settingsUiFlagsProvider =
    NotifierProvider<SettingsUiFlagsNotifier, SettingsUiFlags>(
  SettingsUiFlagsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<SettingsBundle> {
  @override
  Future<SettingsBundle> build() async {
    return _loadAndApplyTheme();
  }

  Future<SettingsBundle> _loadAndApplyTheme() async {
    final repository = ref.read(settingsRepositoryProvider);
    final bundle = await repository.fetchSettings();

    ref.read(themeProvider.notifier).setThemeMode(
          SettingsDto.themeModeFromApi(bundle.preferences.themeMode),
        );

    return bundle;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_loadAndApplyTheme);
  }

  void _refreshDependentScreens() {
    Future.microtask(() => ref.invalidate(homeDashboardProvider));
  }

  SettingsUiFlags get _flags => ref.read(settingsUiFlagsProvider);

  void _setFlags(SettingsUiFlags flags) {
    ref.read(settingsUiFlagsProvider.notifier).state = flags;
  }

  SettingsBundle _requireBundle() {
    final current = state.value;
    if (current == null) {
      throw const ApiException(
        message: 'Settings not loaded yet. Pull to refresh and try again.',
        code: 'NOT_READY',
      );
    }
    return current;
  }

  Future<void> saveAllowance({
    required double monthlyAmount,
    required int cycleStartDay,
  }) async {
    final current = _requireBundle();

    final clampedDay = cycleStartDay.clamp(1, 28);
    _setFlags(_flags.copyWith(isSavingAllowance: true));

    try {
      final allowance = await ref.read(settingsRepositoryProvider).updateAllowance(
            monthlyAmount: monthlyAmount,
            cycleStartDay: clampedDay,
          );

      state = AsyncData(current.copyWith(allowance: allowance));
      _refreshDependentScreens();
    } finally {
      _setFlags(_flags.copyWith(isSavingAllowance: false));
    }
  }

  Future<PaymentAccountSettings> addAccount({
    required String name,
    required String type,
  }) async {
    final current = _requireBundle();

    _setFlags(_flags.copyWith(isAddingAccount: true));

    try {
      final account = await ref.read(settingsRepositoryProvider).createAccount(
            name: name,
            type: type,
          );

      state = AsyncData(
        current.copyWith(accounts: [account, ...current.accounts]),
      );
      _refreshDependentScreens();

      return account;
    } finally {
      _setFlags(_flags.copyWith(isAddingAccount: false));
    }
  }

  Future<void> removeAccount(String accountId) async {
    final current = _requireBundle();

    final previous = List<PaymentAccountSettings>.from(current.accounts);
    _setFlags(_flags.copyWith(deletingAccountId: accountId));

    state = AsyncData(
      current.copyWith(
        accounts: previous.where((a) => a.id != accountId).toList(),
      ),
    );

    try {
      await ref.read(settingsRepositoryProvider).deleteAccount(accountId);
      _refreshDependentScreens();
    } catch (error) {
      state = AsyncData(current.copyWith(accounts: previous));
      rethrow;
    } finally {
      _setFlags(_flags.copyWith(clearDeletingAccountId: true));
    }
  }

  Future<void> updateLanguage(String language) async {
    final current = _requireBundle();

    final previousLanguage = current.preferences.preferredLanguage;
    _setFlags(_flags.copyWith(isUpdatingPreferences: true));

    state = AsyncData(
      current.copyWith(
        preferences: current.preferences.copyWith(
          preferredLanguage: language,
        ),
      ),
    );

    try {
      final preferences =
          await ref.read(settingsRepositoryProvider).updatePreferences(
                preferredLanguage: language,
                themeMode: current.preferences.themeMode,
              );

      state = AsyncData(current.copyWith(preferences: preferences));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          preferences: current.preferences.copyWith(
            preferredLanguage: previousLanguage,
          ),
        ),
      );
      rethrow;
    } finally {
      _setFlags(_flags.copyWith(isUpdatingPreferences: false));
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = _requireBundle();

    final apiTheme = SettingsDto.themeModeToApi(mode);
    final previousTheme = current.preferences.themeMode;

    ref.read(themeProvider.notifier).setThemeMode(mode);
    _setFlags(_flags.copyWith(isUpdatingPreferences: true));

    state = AsyncData(
      current.copyWith(
        preferences: current.preferences.copyWith(themeMode: apiTheme),
      ),
    );

    try {
      final preferences =
          await ref.read(settingsRepositoryProvider).updatePreferences(
                preferredLanguage: current.preferences.preferredLanguage,
                themeMode: apiTheme,
              );

      state = AsyncData(current.copyWith(preferences: preferences));
    } catch (error) {
      ref.read(themeProvider.notifier).setThemeMode(
            SettingsDto.themeModeFromApi(previousTheme),
          );
      state = AsyncData(
        current.copyWith(
          preferences: current.preferences.copyWith(themeMode: previousTheme),
        ),
      );
      rethrow;
    } finally {
      _setFlags(_flags.copyWith(isUpdatingPreferences: false));
    }
  }

  Future<void> deleteUserAccount() async {
    await ref.read(settingsRepositoryProvider).deleteUserAccount();
    await ref.read(authNotifierProvider.notifier).logout();
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsBundle>(
  SettingsNotifier.new,
);

/// Payment accounts from settings; used by transaction forms and other features.
final paymentAccountsProvider = Provider<List<PaymentAccountSettings>>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.maybeWhen(
    data: (bundle) => bundle.accounts,
    orElse: () => const [],
  );
});
