import 'package:sqflite/sqflite.dart';

class TransactionCacheDao {
  TransactionCacheDao(this._database);

  final Database _database;

  static const String tableName = 'cached_transactions';
  static const String metaTableName = 'cache_meta';
  static const String lastSyncKey = 'transactions_last_sync_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      transaction_date TEXT NOT NULL,
      display_date TEXT NOT NULL,
      month_label TEXT NOT NULL,
      account_id TEXT,
      account_name TEXT,
      note TEXT,
      icon_key TEXT,
      is_dirty INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      server_updated_at TEXT,
      synced_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createMetaTableSql = '''
    CREATE TABLE IF NOT EXISTS $metaTableName (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static Future<void> ensureSchema(Database database) async {
    await database.execute(createTableSql);
    await database.execute(createMetaTableSql);

    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_transactions_user_id ON $tableName(user_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_transactions_user_date ON $tableName(user_id, transaction_date);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_transactions_user_type ON $tableName(user_id, type);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_transactions_user_category ON $tableName(user_id, category);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_transactions_dirty ON $tableName(user_id, is_dirty);',
    );
  }

  Future<void> clearAllForUser(String userId) async {
    await _database.delete(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteById(String userId, String transactionId) async {
    await _database.delete(
      tableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, transactionId],
    );
  }

  Future<void> softDeleteById(String userId, String transactionId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.update(
      tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
      },
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, transactionId],
    );
  }

  Future<void> upsertMany(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return;
    }

    final batch = _database.batch();
    for (final row in rows) {
      batch.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertOne(Map<String, dynamic> row) async {
    await _database.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAllForUser(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'user_id = ? AND is_dirty = 0',
        whereArgs: [userId],
      );

      if (rows.isNotEmpty) {
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(
            tableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryTransactions({
    required String userId,
    String? type,
    String? category,
    String? fromDate,
    String? toDate,
    String? searchQuery,
    String sort = 'date_desc',
    int? limit,
    int? offset,
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?'];
    final whereArgs = <Object?>[userId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    if (type != null && type.isNotEmpty && type != 'All') {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }

    if (category != null && category.isNotEmpty) {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      whereParts.add('date(transaction_date) >= date(?)');
      whereArgs.add(fromDate);
    }

    if (toDate != null && toDate.isNotEmpty) {
      whereParts.add('date(transaction_date) <= date(?)');
      whereArgs.add(toDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereParts.add(
        '(title LIKE ? OR category LIKE ? OR IFNULL(note, \'\') LIKE ?)',
      );
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    var sql = '''
      SELECT *
      FROM $tableName
      WHERE ${whereParts.join(' AND ')}
      ORDER BY ${_resolveSort(sort)}
    ''';

    if (limit != null) {
      sql += ' LIMIT $limit';
      if (offset != null) {
        sql += ' OFFSET $offset';
      }
    }

    return _database.rawQuery(sql, whereArgs);
  }

  Future<Map<String, dynamic>?> findById(String userId, String transactionId) async {
    final rows = await _database.query(
      tableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, transactionId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<int> countTransactions({
    required String userId,
    String? type,
    String? category,
    String? fromDate,
    String? toDate,
    String? searchQuery,
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?'];
    final whereArgs = <Object?>[userId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    if (type != null && type.isNotEmpty && type != 'All') {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }

    if (category != null && category.isNotEmpty) {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      whereParts.add('date(transaction_date) >= date(?)');
      whereArgs.add(fromDate);
    }

    if (toDate != null && toDate.isNotEmpty) {
      whereParts.add('date(transaction_date) <= date(?)');
      whereArgs.add(toDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereParts.add(
        '(title LIKE ? OR category LIKE ? OR IFNULL(note, \'\') LIKE ?)',
      );
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final result = await _database.rawQuery(
      '''
        SELECT COUNT(*) AS total
        FROM $tableName
        WHERE ${whereParts.join(' AND ')};
      ''',
      whereArgs,
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['total'] as int?) ?? 0;
  }

  Future<bool> hasAnyForUser(String userId) async {
    final result = await _database.rawQuery(
      '''
        SELECT COUNT(*) AS total
        FROM $tableName
        WHERE user_id = ? AND is_deleted = 0;
      ''',
      [userId],
    );

    final total = (result.first['total'] as int?) ?? 0;
    return total > 0;
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

  Future<List<Map<String, dynamic>>> getDirtyTransactions(String userId) async {
    return _database.query(
      tableName,
      where: 'user_id = ? AND is_dirty = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at ASC',
    );
  }

  String _resolveSort(String sort) {
    switch (sort) {
      case 'date_asc':
        return 'transaction_date ASC, created_at ASC';
      case 'amount_desc':
        return 'amount DESC, transaction_date DESC';
      case 'amount_asc':
        return 'amount ASC, transaction_date DESC';
      case 'date_desc':
      default:
        return 'transaction_date DESC, created_at DESC';
    }
  }
}