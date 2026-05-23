import 'package:sqflite/sqflite.dart';

class GoalCacheDao {
  GoalCacheDao(this._database);

  final Database _database;

  static const String goalsTableName = 'cached_goals';
  static const String depositsTableName = 'cached_goal_deposits';
  static const String metaTableName = 'cache_meta';
  static const String lastSyncKey = 'goals_last_sync_at';

  static const String createGoalsTableSql = '''
    CREATE TABLE IF NOT EXISTS $goalsTableName (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      period TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL,
      due_date TEXT NOT NULL,
      due_date_display TEXT NOT NULL,
      note TEXT,
      status TEXT NOT NULL,
      is_locked INTEGER NOT NULL DEFAULT 0,
      is_completed INTEGER NOT NULL DEFAULT 0,
      progress REAL NOT NULL DEFAULT 0,
      completed_at TEXT,
      is_dirty INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      server_updated_at TEXT,
      synced_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createDepositsTableSql = '''
    CREATE TABLE IF NOT EXISTS $depositsTableName (
      id TEXT PRIMARY KEY,
      goal_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      amount REAL NOT NULL,
      source TEXT NOT NULL,
      account_id TEXT,
      deposited_at TEXT NOT NULL,
      is_dirty INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      server_updated_at TEXT,
      synced_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (goal_id) REFERENCES $goalsTableName(id) ON DELETE CASCADE
    );
  ''';

  static const String createMetaTableSql = '''
    CREATE TABLE IF NOT EXISTS $metaTableName (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static Future<void> ensureSchema(Database database) async {
    await database.execute(createGoalsTableSql);
    await database.execute(createDepositsTableSql);
    await database.execute(createMetaTableSql);

    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goals_user_id ON $goalsTableName(user_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goals_user_status ON $goalsTableName(user_id, status);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goals_user_due_date ON $goalsTableName(user_id, due_date);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goals_dirty ON $goalsTableName(user_id, is_dirty);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goal_deposits_goal_id ON $depositsTableName(goal_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goal_deposits_user_id ON $depositsTableName(user_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_goal_deposits_dirty ON $depositsTableName(user_id, is_dirty);',
    );
  }

  Future<void> clearAllForUser(String userId) async {
    await _database.delete(
      depositsTableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await _database.delete(
      goalsTableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteGoalById(String userId, String goalId) async {
    await _database.delete(
      goalsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, goalId],
    );
  }

  Future<void> deleteDepositById(String userId, String depositId) async {
    await _database.delete(
      depositsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, depositId],
    );
  }

  Future<void> softDeleteGoalById(String userId, String goalId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.update(
      goalsTableName,
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': now,
      },
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, goalId],
    );
  }

  Future<void> upsertGoal(Map<String, dynamic> row) async {
    await _database.insert(
      goalsTableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertGoals(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return;
    }

    final batch = _database.batch();
    for (final row in rows) {
      batch.insert(
        goalsTableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertDeposit(Map<String, dynamic> row) async {
    await _database.insert(
      depositsTableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAllGoalsForUser(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        goalsTableName,
        where: 'user_id = ? AND is_dirty = 0',
        whereArgs: [userId],
      );

      if (rows.isNotEmpty) {
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(
            goalsTableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<void> replaceDepositsForGoal(
    String userId,
    String goalId,
    List<Map<String, dynamic>> rows,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        depositsTableName,
        where: 'user_id = ? AND goal_id = ? AND is_dirty = 0',
        whereArgs: [userId, goalId],
      );

      if (rows.isNotEmpty) {
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(
            depositsTableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryGoals({
    required String userId,
    String status = 'all',
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?'];
    final whereArgs = <Object?>[userId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus != 'all' && normalizedStatus.isNotEmpty) {
      whereParts.add('status = ?');
      whereArgs.add(normalizedStatus);
    }

    return _database.query(
      goalsTableName,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'due_date ASC, created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> findGoalById(
    String userId,
    String goalId,
  ) async {
    final rows = await _database.query(
      goalsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, goalId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<List<Map<String, dynamic>>> queryDepositsForGoal({
    required String userId,
    required String goalId,
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?', 'goal_id = ?'];
    final whereArgs = <Object?>[userId, goalId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    return _database.query(
      depositsTableName,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'deposited_at DESC, created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDirtyGoals(String userId) async {
    return _database.query(
      goalsTableName,
      where: 'user_id = ? AND is_dirty = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getDirtyDeposits(String userId) async {
    return _database.query(
      depositsTableName,
      where: 'user_id = ? AND is_dirty = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  Future<bool> hasAnyGoalsForUser(String userId) async {
    final result = await _database.rawQuery(
      '''
        SELECT COUNT(*) AS total
        FROM $goalsTableName
        WHERE user_id = ? AND is_deleted = 0;
      ''',
      [userId],
    );

    return ((result.first['total'] as int?) ?? 0) > 0;
  }

  Future<DateTime?> getLastSyncAt() async {
    final rows = await _database.query(
      metaTableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [lastSyncKey],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value']?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<void> setLastSyncAt(DateTime timestamp) async {
    await _database.insert(
      metaTableName,
      {
        'key': lastSyncKey,
        'value': timestamp.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}