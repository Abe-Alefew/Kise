// Standalone tests for TokenStorage — read/write/clear using the
// SharedPreferences mock store. These verify the storage keys, null defaults,
// and idempotent overwrite behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/auth/data/datasources/token_storage.dart';

void main() {
  late TokenStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = TokenStorage();
  });

  // ────────────────────────────────────────────────────
  // Key constants
  // ────────────────────────────────────────────────────
  group('TokenStorageKeys', () {
    test('accessToken key is "kise_access_token"', () {
      expect(TokenStorageKeys.accessToken, 'kise_access_token');
    });

    test('refreshToken key is "kise_refresh_token"', () {
      expect(TokenStorageKeys.refreshToken, 'kise_refresh_token');
    });

    test('keys are distinct', () {
      expect(TokenStorageKeys.accessToken, isNot(TokenStorageKeys.refreshToken));
    });
  });

  // ────────────────────────────────────────────────────
  // readAccessToken
  // ────────────────────────────────────────────────────
  group('readAccessToken', () {
    test('returns null when nothing stored', () async {
      expect(await storage.readAccessToken(), isNull);
    });

    test('returns stored access token after save', () async {
      await storage.saveTokens(
          accessToken: 'acc-tok', refreshToken: 'ref-tok');
      expect(await storage.readAccessToken(), 'acc-tok');
    });

    test('returns null after clearTokens', () async {
      await storage.saveTokens(
          accessToken: 'acc', refreshToken: 'ref');
      await storage.clearTokens();
      expect(await storage.readAccessToken(), isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // readRefreshToken
  // ────────────────────────────────────────────────────
  group('readRefreshToken', () {
    test('returns null when nothing stored', () async {
      expect(await storage.readRefreshToken(), isNull);
    });

    test('returns stored refresh token after save', () async {
      await storage.saveTokens(
          accessToken: 'acc', refreshToken: 'ref-tok');
      expect(await storage.readRefreshToken(), 'ref-tok');
    });

    test('returns null after clearTokens', () async {
      await storage.saveTokens(
          accessToken: 'acc', refreshToken: 'ref');
      await storage.clearTokens();
      expect(await storage.readRefreshToken(), isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // saveTokens
  // ────────────────────────────────────────────────────
  group('saveTokens', () {
    test('stores both tokens simultaneously', () async {
      await storage.saveTokens(
          accessToken: 'new-access', refreshToken: 'new-refresh');
      expect(await storage.readAccessToken(), 'new-access');
      expect(await storage.readRefreshToken(), 'new-refresh');
    });

    test('overwrites existing tokens on second call', () async {
      await storage.saveTokens(
          accessToken: 'old-access', refreshToken: 'old-refresh');
      await storage.saveTokens(
          accessToken: 'new-access', refreshToken: 'new-refresh');
      expect(await storage.readAccessToken(), 'new-access');
      expect(await storage.readRefreshToken(), 'new-refresh');
    });

    test('is idempotent — calling twice produces same result', () async {
      await storage.saveTokens(
          accessToken: 'tok', refreshToken: 'rtok');
      await storage.saveTokens(
          accessToken: 'tok', refreshToken: 'rtok');
      expect(await storage.readAccessToken(), 'tok');
    });

    test('stores different access and refresh values independently', () async {
      await storage.saveTokens(
          accessToken: 'access-xyz', refreshToken: 'refresh-abc');
      expect(await storage.readAccessToken(), 'access-xyz');
      expect(await storage.readRefreshToken(), 'refresh-abc');
      expect(await storage.readAccessToken(),
          isNot(await storage.readRefreshToken()));
    });
  });

  // ────────────────────────────────────────────────────
  // clearTokens
  // ────────────────────────────────────────────────────
  group('clearTokens', () {
    test('removes both tokens', () async {
      await storage.saveTokens(
          accessToken: 'acc', refreshToken: 'ref');
      await storage.clearTokens();
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });

    test('does not throw when no tokens are stored', () async {
      await expectLater(storage.clearTokens(), completes);
    });

    test('calling clearTokens twice does not throw', () async {
      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
      await storage.clearTokens();
      await expectLater(storage.clearTokens(), completes);
    });
  });

  // ────────────────────────────────────────────────────
  // Persistence across multiple TokenStorage instances
  // ────────────────────────────────────────────────────
  group('multiple instances share the same store', () {
    test('token written by one instance is readable by another', () async {
      final writer = TokenStorage();
      final reader = TokenStorage();

      await writer.saveTokens(accessToken: 'shared', refreshToken: 'shared-r');
      expect(await reader.readAccessToken(), 'shared');
    });
  });
}
