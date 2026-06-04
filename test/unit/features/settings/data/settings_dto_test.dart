// Tests for SettingsDto — static parsing helpers for account, allowance,
// preferences, and ThemeMode ↔ API string conversion.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kise/features/settings/data/dtos/settings_dto.dart';

void main() {
  // ────────────────────────────────────────────────────
  // SettingsDto.accountFromJson
  // ────────────────────────────────────────────────────
  group('SettingsDto.accountFromJson', () {
    test('parses id, name, type correctly', () {
      final account = SettingsDto.accountFromJson({
        'id': 'acc-001',
        'name': 'Commercial Bank of Ethiopia',
        'type': 'bank',
      });
      expect(account.id, 'acc-001');
      expect(account.name, 'Commercial Bank of Ethiopia');
      expect(account.type, 'bank');
    });

    test('defaults missing id to empty string', () {
      final account = SettingsDto.accountFromJson({'name': 'X', 'type': 'bank'});
      expect(account.id, '');
    });

    test('defaults missing name to empty string', () {
      final account = SettingsDto.accountFromJson({'id': '1', 'type': 'bank'});
      expect(account.name, '');
    });

    test('defaults missing type to "Other"', () {
      final account = SettingsDto.accountFromJson({'id': '1', 'name': 'X'});
      expect(account.type, 'Other');
    });

    test('handles null values gracefully', () {
      final account = SettingsDto.accountFromJson({
        'id': null,
        'name': null,
        'type': null,
      });
      expect(account.id, '');
      expect(account.name, '');
      expect(account.type, 'Other');
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsDto.accountListFromJson
  // ────────────────────────────────────────────────────
  group('SettingsDto.accountListFromJson', () {
    test('parses a list of account maps', () {
      final list = SettingsDto.accountListFromJson([
        {'id': 'a1', 'name': 'CBE', 'type': 'bank'},
        {'id': 'a2', 'name': 'Telebirr', 'type': 'mobile_money'},
      ]);
      expect(list, hasLength(2));
      expect(list[0].id, 'a1');
      expect(list[1].name, 'Telebirr');
    });

    test('returns empty list when input is not a List', () {
      expect(SettingsDto.accountListFromJson(null), isEmpty);
      expect(SettingsDto.accountListFromJson('bad'), isEmpty);
      expect(SettingsDto.accountListFromJson({'id': '1'}), isEmpty);
    });

    test('returns empty list for an empty List', () {
      expect(SettingsDto.accountListFromJson([]), isEmpty);
    });

    test('skips non-map entries inside the list', () {
      final list = SettingsDto.accountListFromJson([
        {'id': 'a1', 'name': 'CBE', 'type': 'bank'},
        'bad-entry',
        42,
      ]);
      expect(list, hasLength(1));
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsDto.allowanceFromJson
  // ────────────────────────────────────────────────────
  group('SettingsDto.allowanceFromJson', () {
    test('parses monthlyAmount, cycleStartDay, isConfigured', () {
      final allowance = SettingsDto.allowanceFromJson({
        'monthlyAmount': 3000.0,
        'cycleStartDay': 1,
        'isConfigured': true,
      });
      expect(allowance.monthlyAmount, 3000.0);
      expect(allowance.cycleStartDay, 1);
      expect(allowance.isConfigured, isTrue);
    });

    test('defaults monthlyAmount to 0 when missing', () {
      final allowance = SettingsDto.allowanceFromJson(
          {'cycleStartDay': 1, 'isConfigured': false});
      expect(allowance.monthlyAmount, 0.0);
    });

    test('defaults cycleStartDay to 1 when missing', () {
      final allowance = SettingsDto.allowanceFromJson({'isConfigured': true});
      expect(allowance.cycleStartDay, 1);
    });

    test('isConfigured defaults to false when missing', () {
      final allowance = SettingsDto.allowanceFromJson({'monthlyAmount': 1000});
      expect(allowance.isConfigured, isFalse);
    });

    test('handles integer monthlyAmount (coerces to double)', () {
      final allowance = SettingsDto.allowanceFromJson({'monthlyAmount': 5000});
      expect(allowance.monthlyAmount, 5000.0);
    });

    test('isConfigured=false when value is not exactly true', () {
      final allowance = SettingsDto.allowanceFromJson({'isConfigured': 1});
      expect(allowance.isConfigured, isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsDto.preferencesFromJson
  // ────────────────────────────────────────────────────
  group('SettingsDto.preferencesFromJson', () {
    test('parses preferredLanguage and themeMode', () {
      final prefs = SettingsDto.preferencesFromJson({
        'preferredLanguage': 'Amharic',
        'themeMode': 'dark',
      });
      expect(prefs.preferredLanguage, 'Amharic');
      expect(prefs.themeMode, 'dark');
    });

    test('defaults preferredLanguage to "English"', () {
      final prefs = SettingsDto.preferencesFromJson({'themeMode': 'light'});
      expect(prefs.preferredLanguage, 'English');
    });

    test('defaults themeMode to "system"', () {
      final prefs =
          SettingsDto.preferencesFromJson({'preferredLanguage': 'English'});
      expect(prefs.themeMode, 'system');
    });

    test('handles null values with defaults', () {
      final prefs = SettingsDto.preferencesFromJson({
        'preferredLanguage': null,
        'themeMode': null,
      });
      expect(prefs.preferredLanguage, 'English');
      expect(prefs.themeMode, 'system');
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsDto.themeModeFromApi
  // ────────────────────────────────────────────────────
  group('SettingsDto.themeModeFromApi', () {
    test('"light" → ThemeMode.light', () {
      expect(SettingsDto.themeModeFromApi('light'), ThemeMode.light);
    });

    test('"dark" → ThemeMode.dark', () {
      expect(SettingsDto.themeModeFromApi('dark'), ThemeMode.dark);
    });

    test('"system" → ThemeMode.system', () {
      expect(SettingsDto.themeModeFromApi('system'), ThemeMode.system);
    });

    test('unknown value defaults to ThemeMode.system', () {
      expect(SettingsDto.themeModeFromApi('auto'), ThemeMode.system);
      expect(SettingsDto.themeModeFromApi(''), ThemeMode.system);
    });
  });

  // ────────────────────────────────────────────────────
  // SettingsDto.themeModeToApi
  // ────────────────────────────────────────────────────
  group('SettingsDto.themeModeToApi', () {
    test('ThemeMode.light → "light"', () {
      expect(SettingsDto.themeModeToApi(ThemeMode.light), 'light');
    });

    test('ThemeMode.dark → "dark"', () {
      expect(SettingsDto.themeModeToApi(ThemeMode.dark), 'dark');
    });

    test('ThemeMode.system → "system"', () {
      expect(SettingsDto.themeModeToApi(ThemeMode.system), 'system');
    });

    test('round-trip: fromApi(toApi(mode)) == mode', () {
      for (final mode in ThemeMode.values) {
        expect(
          SettingsDto.themeModeFromApi(SettingsDto.themeModeToApi(mode)),
          mode,
        );
      }
    });
  });
}