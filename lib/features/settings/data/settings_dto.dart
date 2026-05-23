import 'package:flutter/material.dart';
import 'package:kise/features/settings/domain/settings_models.dart';

abstract final class SettingsDto {
  static PaymentAccountSettings accountFromJson(Map<String, dynamic> json) {
    return PaymentAccountSettings(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Other',
    );
  }

  static List<PaymentAccountSettings> accountListFromJson(dynamic json) {
    if (json is! List) {
      return const [];
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(accountFromJson)
        .toList();
  }

  static AllowanceSettings allowanceFromJson(Map<String, dynamic> json) {
    return AllowanceSettings(
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0,
      cycleStartDay: (json['cycleStartDay'] as num?)?.toInt() ?? 1,
      isConfigured: json['isConfigured'] == true,
    );
  }

  static UserPreferencesSettings preferencesFromJson(Map<String, dynamic> json) {
    return UserPreferencesSettings(
      preferredLanguage: json['preferredLanguage'] as String? ?? 'English',
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }

  static ThemeMode themeModeFromApi(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToApi(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
