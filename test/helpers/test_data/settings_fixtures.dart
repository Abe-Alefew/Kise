import 'package:kise/features/settings/domain/settings_models.dart';

const testAllowance = AllowanceSettings(
  monthlyAmount: 3000.0,
  cycleStartDay: 1,
  isConfigured: true,
);

const testPreferences = UserPreferencesSettings(
  preferredLanguage: 'English',
  themeMode: 'system',
);

const testAccount = PaymentAccountSettings(
  id: 'acc-fixture-001',
  name: 'Commercial Bank',
  type: 'bank',
);

const testSettingsBundle = SettingsBundle(
  accounts: [testAccount],
  allowance: testAllowance,
  preferences: testPreferences,
);
