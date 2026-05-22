import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this._database);

  static const String _databaseName = 'kise_local.db';
  static const int _databaseVersion = 1;

  final Database _database;

  Database get database => _database;

  static Future<AppDatabase> open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    final database = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return AppDatabase._(database);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT,
        username TEXT,
        school TEXT,
        department TEXT,
        year_of_study INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'ETB',
        preferred_language TEXT NOT NULL DEFAULT 'English',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        synced_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE local_user_preferences (
        user_id TEXT PRIMARY KEY,
        preferred_language TEXT NOT NULL DEFAULT 'English',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        synced_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES local_users(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE local_allowance_settings (
        user_id TEXT PRIMARY KEY,
        monthly_amount REAL NOT NULL DEFAULT 0,
        cycle_start_day INTEGER NOT NULL DEFAULT 1,
        synced_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES local_users(id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_local_users_email ON local_users(email);',
    );
    await db.execute(
      'CREATE INDEX idx_local_user_preferences_language ON local_user_preferences(preferred_language);',
    );
    await db.execute(
      'CREATE INDEX idx_local_allowance_user_id ON local_allowance_settings(user_id);',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= newVersion) {
      return;
    }

    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }

  Future<void> upsertUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    String? username,
    required String school,
    required String department,
    required int yearOfStudy,
    required String currency,
    required String preferredLanguage,
    required String themeMode,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.insert(
      'local_users',
      {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'username': username,
        'school': school,
        'department': department,
        'year_of_study': yearOfStudy,
        'currency': currency,
        'preferred_language': preferredLanguage,
        'theme_mode': themeMode,
        'synced_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await upsertUserPreferences(
      userId: id,
      preferredLanguage: preferredLanguage,
      themeMode: themeMode,
    );
  }

  Future<void> upsertUserPreferences({
    required String userId,
    required String preferredLanguage,
    required String themeMode,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.insert(
      'local_user_preferences',
      {
        'user_id': userId,
        'preferred_language': preferredLanguage,
        'theme_mode': themeMode,
        'synced_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllowanceSettings({
    required String userId,
    required double monthlyAmount,
    required int cycleStartDay,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.insert(
      'local_allowance_settings',
      {
        'user_id': userId,
        'monthly_amount': monthlyAmount,
        'cycle_start_day': cycleStartDay,
        'synced_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final rows = await _database.query(
      'local_users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    final rows = await _database.query(
      'local_user_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<Map<String, dynamic>?> getAllowanceSettings(String userId) async {
    final rows = await _database.query(
      'local_allowance_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<void> clearUserData() async {
    await _database.delete('local_allowance_settings');
    await _database.delete('local_user_preferences');
    await _database.delete('local_users');
  }

  Future<void> close() async {
    await _database.close();
  }
}

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(() {
    db.close();
  });
  return db;
});