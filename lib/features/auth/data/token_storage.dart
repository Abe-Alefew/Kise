import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class SecureStorageKeys {
  static const String accessToken = 'kise_access_token';
  static const String refreshToken = 'kise_refresh_token';
}

class TokenStorage {
  TokenStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
               
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _secureStorage;

  Future<String?> readAccessToken() {
    return _secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() {
    return _secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(
      key: SecureStorageKeys.accessToken,
      value: accessToken,
    );
    await _secureStorage.write(
      key: SecureStorageKeys.refreshToken,
      value: refreshToken,
    );
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: SecureStorageKeys.accessToken);
    await _secureStorage.delete(key: SecureStorageKeys.refreshToken);
  }
}