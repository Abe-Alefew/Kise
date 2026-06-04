import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/settings/domain/settings_models.dart';

void main() {
  // ────────────────────────────────────────────────────
  // PaymentAccountSettings
  // ────────────────────────────────────────────────────
  group('PaymentAccountSettings', () {
    const account = PaymentAccountSettings(
      id: 'acc-001',
      name: 'Commercial Bank of Ethiopia',
      type: 'bank',
    );

    test('stores all fields', () {
      expect(account.id, 'acc-001');
      expect(account.name, 'Commercial Bank of Ethiopia');
      expect(account.type, 'bank');
    });

    test('copyWith preserves unchanged fields', () {
      final copy = account.copyWith();
      expect(copy.id, account.id);
      expect(copy.name, account.name);
      expect(copy.type, account.type);
    });

    test('copyWith updates name only', () {
      final copy = account.copyWith(name: 'Abyssinia Bank');
      expect(copy.name, 'Abyssinia Bank');
      expect(copy.id, 'acc-001');
      expect(copy.type, 'bank');
    });

    test('copyWith updates type only', () {
      final copy = account.copyWith(type: 'mobile_money');
      expect(copy.type, 'mobile_money');
      expect(copy.name, account.name);
    });

    test('copyWith updates all fields at once', () {
      final copy = account.copyWith(id: 'acc-002', name: 'Telebirr', type: 'mobile_money');
      expect(copy.id, 'acc-002');
      expect(copy.name, 'Telebirr');
      expect(copy.type, 'mobile_money');
    });
  });

  // ────────────────────────────────────────────────────
  // AllowanceSettings
  // ────────────────────────────────────────────────────
  group('AllowanceSettings', () {
    const allowance = AllowanceSettings(
      monthlyAmount: 3000.0,
      cycleStartDay: 1,
      isConfigured: true,
    );

    test('stores all fields', () {
      expect(allowance.monthlyAmount, 3000.0);
      expect(allowance.cycleStartDay, 1);
      expect(allowance.isConfigured, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = allowance.copyWith();
      expect(copy.monthlyAmount, 3000.0);
      expect(copy.cycleStartDay, 1);
      expect(copy.isConfigured, isTrue);
    });

    test('copyWith updates monthlyAmount', () {
      final copy = allowance.copyWith(monthlyAmount: 5000.0);
      expect(copy.monthlyAmount, 5000.0);
      expect(copy.cycleStartDay, 1); // unchanged
    });

    test('copyWith updates cycleStartDay', () {
      final copy = allowance.copyWith(cycleStartDay: 15);
      expect(copy.cycleStartDay, 15);
      expect(copy.monthlyAmount, 3000.0);
    });

    test('copyWith can set isConfigured to false', () {
      final copy = allowance.copyWith(isConfigured: false);
      expect(copy.isConfigured, isFalse);
    });

    test('unconfigured allowance defaults', () {
      const unconfigured = AllowanceSettings(
        monthlyAmount: 0,
        cycleStartDay: 1,
        isConfigured: false,
      );
      expect(unconfigured.isConfigured, isFalse);
      expect(unconfigured.monthlyAmount, 0.0);
    });
  });

  // ────────────────────────────────────────────────────
  // UserPreferencesSettings
  // ────────────────────────────────────────────────────
  group('UserPreferencesSettings', () {
    const prefs = UserPreferencesSettings(
      preferredLanguage: 'English',
      themeMode: 'system',
    );

    test('stores all fields', () {
      expect(prefs.preferredLanguage, 'English');
      expect(prefs.themeMode, 'system');
    });

    test('copyWith preserves unchanged fields', () {
      final copy = prefs.copyWith();
      expect(copy.preferredLanguage, 'English');
      expect(copy.themeMode, 'system');
    });

    test('copyWith updates preferredLanguage', () {
      final copy = prefs.copyWith(preferredLanguage: 'Amharic');
      expect(copy.preferredLanguage, 'Amharic');
      expect(copy.themeMode, 'system');
    });

    test('copyWith switches themeMode to dark', () {
      final copy = prefs.copyWith(themeMode: 'dark');
      expect(copy.themeMode, 'dark');
      expect(copy.preferredLanguage, 'English');
    });

    test('copyWith switches themeMode to light', () {
      final copy = prefs.copyWith(themeMode: 'light');
      expect(copy.themeMode, 'light');
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsBundle
  // ────────────────────────────────────────────────────
  group('SettingsBundle', () {
    const account = PaymentAccountSettings(id: 'a1', name: 'CBE', type: 'bank');
    const allowance = AllowanceSettings(
      monthlyAmount: 2000,
      cycleStartDay: 1,
      isConfigured: true,
    );
    const preferences = UserPreferencesSettings(
      preferredLanguage: 'Amharic',
      themeMode: 'light',
    );
    const bundle = SettingsBundle(
      accounts: [account],
      allowance: allowance,
      preferences: preferences,
    );

    test('stores all sub-models', () {
      expect(bundle.accounts, hasLength(1));
      expect(bundle.accounts.first.name, 'CBE');
      expect(bundle.allowance.monthlyAmount, 2000.0);
      expect(bundle.preferences.themeMode, 'light');
    });

    test('copyWith preserves all fields when no args', () {
      final copy = bundle.copyWith();
      expect(copy.accounts, bundle.accounts);
      expect(copy.allowance.monthlyAmount, bundle.allowance.monthlyAmount);
      expect(copy.preferences.preferredLanguage,
          bundle.preferences.preferredLanguage);
    });

    test('copyWith updates allowance only', () {
      final newAllowance = allowance.copyWith(monthlyAmount: 5000);
      final copy = bundle.copyWith(allowance: newAllowance);
      expect(copy.allowance.monthlyAmount, 5000.0);
      expect(copy.accounts, bundle.accounts);
      expect(copy.preferences.themeMode, 'light');
    });

    test('copyWith replaces accounts list', () {
      const newAccount = PaymentAccountSettings(id: 'a2', name: 'Abyssinia', type: 'bank');
      final copy = bundle.copyWith(accounts: [account, newAccount]);
      expect(copy.accounts, hasLength(2));
    });

    test('copyWith updates preferences only', () {
      final newPrefs = preferences.copyWith(themeMode: 'dark');
      final copy = bundle.copyWith(preferences: newPrefs);
      expect(copy.preferences.themeMode, 'dark');
      expect(copy.allowance.monthlyAmount, 2000.0);
    });

    test('empty accounts list is valid', () {
      const empty = SettingsBundle(
        accounts: [],
        allowance: AllowanceSettings(
          monthlyAmount: 0,
          cycleStartDay: 1,
          isConfigured: false,
        ),
        preferences: UserPreferencesSettings(
          preferredLanguage: 'English',
          themeMode: 'system',
        ),
      );
      expect(empty.accounts, isEmpty);
    });
  });
}