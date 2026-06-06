// In-memory SQLite database factory for unit tests.
// Uses sqflite_common_ffi — no device or plugin channel required.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once in [setUpAll] or [setUp] before any database access.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Opens a fresh in-memory SQLite database and runs [onCreate] to build
/// the schema.  Registers [addTearDown] so the DB is closed after the test.
Future<Database> openTestDb({
  required Future<void> Function(Database db) onCreate,
}) async {
  initTestDatabase();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => onCreate(db),
    ),
  );
  addTearDown(db.close);
  return db;
}