// Tests for AppDatabase — schema creation, user upsert/query,
// preferences, allowance settings, and clearUserData.
//
// Uses sqflite_common_ffi so no device/plugin channel is needed.
// The FFI backend writes to a temp file on disk; clearUserData() in setUp
// keeps each test isolated without needing to delete the file.

import 'package:flutter_test/flutter_test.dart';

import 'package:kise/core/database/app_database.dart';

import '../../../helpers/database_helper.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    // Redirect all sqflite calls to the FFI (desktop-SQLite) backend.
    initTestDatabase();
  });

  setUp(() async {
    db = await AppDatabase.open();
    // Wipe all rows so each test starts with a clean slate.
    await db.clearUserData();
  });

  tearDown(() => db.close());

  // ── Helper ──────────────────────────────────────────────────────────────────

  Future<void> insertUser({
    String id = 'user-001',
    String email = 'test@kise.app',
    String firstName = 'Abel',
    String lastName = 'Bekele',
    String currency = 'ETB',
    String preferredLanguage = 'English',
    String themeMode = 'system',
  }) =>
      db.upsertUser(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        university: 'AAU',
        department: 'CS',
        currency: currency,
        preferredLanguage: preferredLanguage,
        themeMode: themeMode,
      );

  // ────────────────────────────────────────────────────
  // upsertUser / getUserById
  // ────────────────────────────────────────────────────
  group('upsertUser / getUserById', () {
    test('inserts a user and retrieves it by id', () async {
      await insertUser();

      final row = await db.getUserById('user-001');
      expect(row, isNotNull);
      expect(row!['email'], 'test@kise.app');
      expect(row['first_name'], 'Abel');
      expect(row['last_name'], 'Bekele');
      expect(row['currency'], 'ETB');
    });

    test('returns null for a non-existent user id', () async {
      final row = await db.getUserById('does-not-exist');
      expect(row, isNull);
    });

    test('upsert replaces existing user on conflict', () async {
      await insertUser(email: 'old@kise.app');
      await insertUser(email: 'new@kise.app', currency: 'USD', themeMode: 'dark');

      final row = await db.getUserById('user-001');
      expect(row!['email'], 'new@kise.app');
      expect(row['currency'], 'USD');
      expect(row['theme_mode'], 'dark');
    });

    test('optional phone and username are stored as null by default', () async {
      await insertUser();

      final row = await db.getUserById('user-001');
      expect(row!['phone'], isNull);
      expect(row['username'], isNull);
    });

    test('inserts user with phone and username', () async {
      await db.upsertUser(
        id: 'user-002',
        email: 'b@kise.app',
        firstName: 'B',
        lastName: 'C',
        phone: '+251911000000',
        username: 'bcuser',
        university: 'MIT',
        department: 'EE',
        currency: 'USD',
        preferredLanguage: 'English',
        themeMode: 'light',
      );

      final row = await db.getUserById('user-002');
      expect(row!['phone'], '+251911000000');
      expect(row['username'], 'bcuser');
    });
  });

  // ────────────────────────────────────────────────────
  // getUserPreferences / upsertUserPreferences
  // ────────────────────────────────────────────────────
  group('getUserPreferences / upsertUserPreferences', () {
    test('preferences are created automatically on upsertUser', () async {
      await insertUser(preferredLanguage: 'Amharic', themeMode: 'dark');

      final prefs = await db.getUserPreferences('user-001');
      expect(prefs, isNotNull);
      expect(prefs!['preferred_language'], 'Amharic');
      expect(prefs['theme_mode'], 'dark');
    });

    test('returns null when no preferences row exists for user', () async {
      final prefs = await db.getUserPreferences('no-such-user');
      expect(prefs, isNull);
    });

    test('upsertUserPreferences updates language and theme', () async {
      await insertUser(preferredLanguage: 'English', themeMode: 'system');
      await db.upsertUserPreferences(
        userId: 'user-001',
        preferredLanguage: 'Amharic',
        themeMode: 'light',
      );

      final prefs = await db.getUserPreferences('user-001');
      expect(prefs!['preferred_language'], 'Amharic');
      expect(prefs['theme_mode'], 'light');
    });

    test('upsertUserPreferences is idempotent', () async {
      await insertUser();
      await db.upsertUserPreferences(
          userId: 'user-001', preferredLanguage: 'English', themeMode: 'dark');
      await db.upsertUserPreferences(
          userId: 'user-001', preferredLanguage: 'English', themeMode: 'dark');

      final prefs = await db.getUserPreferences('user-001');
      expect(prefs!['theme_mode'], 'dark');
    });
  });

  // ────────────────────────────────────────────────────
  // getAllowanceSettings / upsertAllowanceSettings
  // ────────────────────────────────────────────────────
  group('getAllowanceSettings / upsertAllowanceSettings', () {
    test('returns null when no allowance has been set', () async {
      await insertUser();
      final row = await db.getAllowanceSettings('user-001');
      expect(row, isNull);
    });

    test('stores and retrieves allowance settings', () async {
      await insertUser();
      await db.upsertAllowanceSettings(
          userId: 'user-001', monthlyAmount: 3000, cycleStartDay: 1);

      final row = await db.getAllowanceSettings('user-001');
      expect(row, isNotNull);
      expect(row!['monthly_amount'], 3000.0);
      expect(row['cycle_start_day'], 1);
    });

    test('upsert replaces existing allowance settings', () async {
      await insertUser();
      await db.upsertAllowanceSettings(
          userId: 'user-001', monthlyAmount: 2000, cycleStartDay: 1);
      await db.upsertAllowanceSettings(
          userId: 'user-001', monthlyAmount: 5000, cycleStartDay: 15);

      final row = await db.getAllowanceSettings('user-001');
      expect(row!['monthly_amount'], 5000.0);
      expect(row['cycle_start_day'], 15);
    });

    test('allowance returns null for unknown user id', () async {
      final row = await db.getAllowanceSettings('unknown');
      expect(row, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // clearUserData
  // ────────────────────────────────────────────────────
  group('clearUserData', () {
    test('removes user, preferences, and allowance', () async {
      await insertUser();
      await db.upsertAllowanceSettings(
          userId: 'user-001', monthlyAmount: 1000, cycleStartDay: 1);

      await db.clearUserData();

      expect(await db.getUserById('user-001'), isNull);
      expect(await db.getUserPreferences('user-001'), isNull);
      expect(await db.getAllowanceSettings('user-001'), isNull);
    });

    test('clears multiple users at once', () async {
      await insertUser(id: 'u1');
      await insertUser(id: 'u2', email: 'u2@x.com');

      await db.clearUserData();

      expect(await db.getUserById('u1'), isNull);
      expect(await db.getUserById('u2'), isNull);
    });

    test('clearUserData on empty database does not throw', () async {
      await expectLater(db.clearUserData(), completes);
    });
  });
}