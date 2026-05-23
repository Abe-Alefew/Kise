import 'package:flutter/foundation.dart';

@immutable
class PaymentAccountSettings {
  final String id;
  final String name;
  final String type;

  const PaymentAccountSettings({
    required this.id,
    required this.name,
    required this.type,
  });

  PaymentAccountSettings copyWith({
    String? id,
    String? name,
    String? type,
  }) {
    return PaymentAccountSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

@immutable
class AllowanceSettings {
  final double monthlyAmount;
  final int cycleStartDay;
  final bool isConfigured;

  const AllowanceSettings({
    required this.monthlyAmount,
    required this.cycleStartDay,
    required this.isConfigured,
  });

  AllowanceSettings copyWith({
    double? monthlyAmount,
    int? cycleStartDay,
    bool? isConfigured,
  }) {
    return AllowanceSettings(
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      cycleStartDay: cycleStartDay ?? this.cycleStartDay,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

@immutable
class UserPreferencesSettings {
  final String preferredLanguage;
  final String themeMode;

  const UserPreferencesSettings({
    required this.preferredLanguage,
    required this.themeMode,
  });

  UserPreferencesSettings copyWith({
    String? preferredLanguage,
    String? themeMode,
  }) {
    return UserPreferencesSettings(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

@immutable
class SettingsBundle {
  final List<PaymentAccountSettings> accounts;
  final AllowanceSettings allowance;
  final UserPreferencesSettings preferences;

  const SettingsBundle({
    required this.accounts,
    required this.allowance,
    required this.preferences,
  });

  SettingsBundle copyWith({
    List<PaymentAccountSettings>? accounts,
    AllowanceSettings? allowance,
    UserPreferencesSettings? preferences,
  }) {
    return SettingsBundle(
      accounts: accounts ?? this.accounts,
      allowance: allowance ?? this.allowance,
      preferences: preferences ?? this.preferences,
    );
  }
}
