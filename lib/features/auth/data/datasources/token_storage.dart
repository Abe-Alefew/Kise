import 'package:shared_preferences/shared_preferences.dart';

abstract final class TokenStorageKeys {
  static const String accessToken = 'kise_access_token';
  static const String refreshToken = 'kise_refresh_token';
}

class TokenStorage {
  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TokenStorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TokenStorageKeys.refreshToken);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TokenStorageKeys.accessToken, accessToken);
    await prefs.setString(TokenStorageKeys.refreshToken, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TokenStorageKeys.accessToken);
    await prefs.remove(TokenStorageKeys.refreshToken);
  }
}
