import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  throw UnimplementedError();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    return ref.watch(initialThemeModeProvider);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveTheme(mode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  static Future<ThemeMode> getStoredTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
