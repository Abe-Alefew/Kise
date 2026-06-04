// Tests for SettingsNotifier, SettingsUiFlags, and paymentAccountsProvider.
// SettingsNotifier.build() calls ref.read(themeProvider.notifier), so
// initialThemeModeProvider must always be overridden in these tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/features/settings/data/repositories/settings_repository.dart';
import 'package:kise/features/settings/domain/settings_models.dart';
import 'package:kise/features/settings/presentation/state/settings_notifier.dart';

import '../helpers/provider_helper.dart';
import '../helpers/test_data/settings_fixtures.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}

// ── Helper ────────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(MockSettingsRepository mockRepo) {
  SharedPreferences.setMockInitialValues({});
  return createContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(mockRepo),
      // ThemeNotifier.build() reads initialThemeModeProvider which throws by
      // default → override it so SettingsNotifier.build() can call setThemeMode
      initialThemeModeProvider.overrideWithValue(ThemeMode.system),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  // ────────────────────────────────────────────────────
  // SettingsNotifier — initial load
  // ────────────────────────────────────────────────────
  group('SettingsNotifier initial load', () {
    test('state starts as AsyncLoading', () {
      when(() => mockRepo.fetchSettings())
          .thenAnswer((_) async => testSettingsBundle);
      final container = _makeContainer(mockRepo);
      expect(container.read(settingsNotifierProvider), isA<AsyncLoading>());
    });

    test('resolves to AsyncData with the SettingsBundle', () async {
      when(() => mockRepo.fetchSettings())
          .thenAnswer((_) async => testSettingsBundle);
      final container = _makeContainer(mockRepo);
      final bundle = await container.read(settingsNotifierProvider.future);
      expect(bundle, isNotNull);
      expect(bundle.allowance.monthlyAmount, 3000.0);
      expect(bundle.preferences.preferredLanguage, 'English');
    });

    test('accounts are loaded from the bundle', () async {
      when(() => mockRepo.fetchSettings())
          .thenAnswer((_) async => testSettingsBundle);
      final container = _makeContainer(mockRepo);
      final bundle = await container.read(settingsNotifierProvider.future);
      expect(bundle.accounts, hasLength(1));
      expect(bundle.accounts.first.name, 'Commercial Bank');
    });

    // Error-path testing for Riverpod 3.x AsyncNotifierProvider is deferred
    // (the internal retry mechanism prevents .future from settling on error).
    // ApiException propagation is covered in auth_notifier_test.dart.
  });

  // ────────────────────────────────────────────────────
  // paymentAccountsProvider (derived)
  // ────────────────────────────────────────────────────
  group('paymentAccountsProvider', () {
    test('returns accounts from loaded settings', () async {
      when(() => mockRepo.fetchSettings())
          .thenAnswer((_) async => testSettingsBundle);
      final container = _makeContainer(mockRepo);
      await container.read(settingsNotifierProvider.future);
      final accounts = container.read(paymentAccountsProvider);
      expect(accounts, hasLength(1));
      expect(accounts.first.name, 'Commercial Bank');
    });

    // Error-path variant deferred — same retry limitation as SettingsNotifier.
  });

  // ────────────────────────────────────────────────────
  // SettingsUiFlags Notifier
  // ────────────────────────────────────────────────────
  group('SettingsUiFlags', () {
    ProviderContainer makeFlagsContainer() {
      SharedPreferences.setMockInitialValues({});
      return createContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.system),
        ],
      );
    }

    test('default state has all flags false and no deletingAccountId', () {
      final container = makeFlagsContainer();
      final flags = container.read(settingsUiFlagsProvider);
      expect(flags.isSavingAllowance, isFalse);
      expect(flags.isAddingAccount, isFalse);
      expect(flags.deletingAccountId, isNull);
      expect(flags.isUpdatingPreferences, isFalse);
    });

    test('copyWith updates isSavingAllowance', () {
      final flags = const SettingsUiFlags().copyWith(isSavingAllowance: true);
      expect(flags.isSavingAllowance, isTrue);
      expect(flags.isAddingAccount, isFalse);
    });

    test('copyWith updates isAddingAccount', () {
      final flags = const SettingsUiFlags().copyWith(isAddingAccount: true);
      expect(flags.isAddingAccount, isTrue);
    });

    test('copyWith sets deletingAccountId', () {
      final flags = const SettingsUiFlags().copyWith(deletingAccountId: 'acc-1');
      expect(flags.deletingAccountId, 'acc-1');
    });

    test('copyWith clearDeletingAccountId removes the id', () {
      final flags = const SettingsUiFlags(deletingAccountId: 'acc-1')
          .copyWith(clearDeletingAccountId: true);
      expect(flags.deletingAccountId, isNull);
    });

    test('copyWith updates isUpdatingPreferences', () {
      final flags =
          const SettingsUiFlags().copyWith(isUpdatingPreferences: true);
      expect(flags.isUpdatingPreferences, isTrue);
    });

    test('copyWith preserves unchanged flags', () {
      const original = SettingsUiFlags(isSavingAllowance: true);
      final copy = original.copyWith(isAddingAccount: true);
      expect(copy.isSavingAllowance, isTrue); // preserved
      expect(copy.isAddingAccount, isTrue);   // updated
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsBundle model
  // ────────────────────────────────────────────────────
  group('SettingsBundle model', () {
    test('copyWith updates allowance', () {
      final updated = testSettingsBundle.copyWith(
        allowance: const AllowanceSettings(
          monthlyAmount: 5000,
          cycleStartDay: 15,
          isConfigured: true,
        ),
      );
      expect(updated.allowance.monthlyAmount, 5000.0);
      expect(updated.accounts, testSettingsBundle.accounts); // unchanged
    });

    test('copyWith updates preferences', () {
      final updated = testSettingsBundle.copyWith(
        preferences: const UserPreferencesSettings(
          preferredLanguage: 'Amharic',
          themeMode: 'dark',
        ),
      );
      expect(updated.preferences.themeMode, 'dark');
      expect(updated.allowance, testSettingsBundle.allowance); // unchanged
    });

    test('copyWith replaces accounts list', () {
      const newAccount = PaymentAccountSettings(
          id: 'a2', name: 'Telebirr', type: 'mobile_money');
      final updated =
          testSettingsBundle.copyWith(accounts: [testAccount, newAccount]);
      expect(updated.accounts, hasLength(2));
    });
  });
}
