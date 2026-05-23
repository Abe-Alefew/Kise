import 'package:sqflite/sqflite.dart';

class DebtLocalSummary {
  final double owedToMe;
  final double iOwe;
  final double netPosition;
  final double recoveryRate;
  final int pendingCount;
  final int partialCount;
  final int settledCount;
  final double totalLent;
  final double totalBorrowed;

  const DebtLocalSummary({
    required this.owedToMe,
    required this.iOwe,
    required this.netPosition,
    required this.recoveryRate,
    required this.pendingCount,
    required this.partialCount,
    required this.settledCount,
    required this.totalLent,
    required this.totalBorrowed,
  });
}

class DebtCacheDao {
  DebtCacheDao(this._database);

  final Database _database;

  static const String debtsTableName = 'cached_debts';
  static const String paymentsTableName = 'cached_debt_payments';
  static const String metaTableName = 'cache_meta';
  static const String lastSyncKey = 'debts_last_sync_at';

  static const String createDebtsTableSql = '''
    CREATE TABLE IF NOT EXISTS $debtsTableName (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      person_name TEXT NOT NULL,
      person_initial TEXT,
      type TEXT NOT NULL,
      total_amount REAL NOT NULL,
      paid_amount REAL NOT NULL,
      remaining REAL NOT NULL,
      status TEXT NOT NULL,
      debt_date TEXT NOT NULL,
      notes TEXT,
      is_dirty INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      server_updated_at TEXT,
      synced_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createPaymentsTableSql = '''
    CREATE TABLE IF NOT EXISTS $paymentsTableName (
      id TEXT PRIMARY KEY,
      debt_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      notes TEXT,
      is_dirty INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      server_updated_at TEXT,
      synced_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (debt_id) REFERENCES $debtsTableName(id) ON DELETE CASCADE
    );
  ''';

  static const String createMetaTableSql = '''
    CREATE TABLE IF NOT EXISTS $metaTableName (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static Future<void> ensureSchema(Database database) async {
    await database.execute(createDebtsTableSql);
    await database.execute(createPaymentsTableSql);
    await database.execute(createMetaTableSql);

    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debts_user_id ON $debtsTableName(user_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debts_user_type ON $debtsTableName(user_id, type);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debts_user_status ON $debtsTableName(user_id, status);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debts_dirty ON $debtsTableName(user_id, is_dirty);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debt_payments_debt_id ON $paymentsTableName(debt_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debt_payments_user_id ON $paymentsTableName(user_id);',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cached_debt_payments_dirty ON $paymentsTableName(user_id, is_dirty);',
    );
  }

  Future<void> clearAllForUser(String userId) async {
    await _database.delete(
      paymentsTableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await _database.delete(
      debtsTableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteDebtById(String userId, String debtId) async {
    await _database.delete(
      debtsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, debtId],
    );
  }

  Future<void> deletePaymentById(String userId, String paymentId) async {
    await _database.delete(
      paymentsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, paymentId],
    );
  }

  Future<void> softDeleteDebtById(String userId, String debtId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.update(
      debtsTableName,
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': now,
      },
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, debtId],
    );
  }

  Future<void> upsertDebt(Map<String, dynamic> row) async {
    await _database.insert(
      debtsTableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertPayment(Map<String, dynamic> row) async {
    await _database.insert(
      paymentsTableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAllDebtsForUser(
    String userId,
    List<Map<String, dynamic>> debtRows,
    List<Map<String, dynamic>> paymentRows,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        paymentsTableName,
        where: 'user_id = ? AND is_dirty = 0',
        whereArgs: [userId],
      );
      await txn.delete(
        debtsTableName,
        where: 'user_id = ? AND is_dirty = 0',
        whereArgs: [userId],
      );

      if (debtRows.isNotEmpty) {
        final debtBatch = txn.batch();
        for (final row in debtRows) {
          debtBatch.insert(
            debtsTableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await debtBatch.commit(noResult: true);
      }

      if (paymentRows.isNotEmpty) {
        final paymentBatch = txn.batch();
        for (final row in paymentRows) {
          paymentBatch.insert(
            paymentsTableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await paymentBatch.commit(noResult: true);
      }
    });
  }

  Future<void> replacePaymentsForDebt(
    String userId,
    String debtId,
    List<Map<String, dynamic>> rows,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        paymentsTableName,
        where: 'user_id = ? AND debt_id = ? AND is_dirty = 0',
        whereArgs: [userId, debtId],
      );

      if (rows.isNotEmpty) {
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(
            paymentsTableName,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryDebts({
    required String userId,
    String filter = 'all',
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?'];
    final whereArgs = <Object?>[userId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    switch (filter.toLowerCase()) {
      case 'active':
        whereParts.add("status != 'settled'");
        break;
      case 'lent':
        whereParts.add("type = 'lent'");
        break;
      case 'borrowed':
        whereParts.add("type = 'borrowed'");
        break;
      case 'settled':
        whereParts.add("status = 'settled'");
        break;
      case 'all':
      default:
        break;
    }

    return _database.query(
      debtsTableName,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'debt_date DESC, created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> findDebtById(
    String userId,
    String debtId,
  ) async {
    final rows = await _database.query(
      debtsTableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, debtId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<List<Map<String, dynamic>>> queryPaymentsForDebt({
    required String userId,
    required String debtId,
    bool includeDeleted = false,
  }) async {
    final whereParts = <String>['user_id = ?', 'debt_id = ?'];
    final whereArgs = <Object?>[userId, debtId];

    if (!includeDeleted) {
      whereParts.add('is_deleted = 0');
    }

    return _database.query(
      paymentsTableName,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'payment_date DESC, created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDirtyDebts(String userId) async {
    return _database.query(
      debtsTableName,
      where: 'user_id = ? AND is_dirty = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at ASC',
    );
  }

  /// Removes stale offline-only rows left from older sync flows.
  Future<void> clearDirtyEntriesForUser(String userId) async {
    await _database.transaction((txn) async {
      await txn.delete(
        paymentsTableName,
        where: 'user_id = ? AND is_dirty = 1',
        whereArgs: [userId],
      );
      await txn.delete(
        debtsTableName,
        where: 'user_id = ? AND is_dirty = 1',
        whereArgs: [userId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getDirtyPayments(String userId) async {
    return _database.query(
      paymentsTableName,
      where: 'user_id = ? AND is_dirty = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  Future<DebtLocalSummary> computeLocalSummary(String userId) async {
    final rows = await _database.query(
      debtsTableName,
      columns: [
        'type',
        'total_amount',
        'paid_amount',
        'remaining',
        'status',
      ],
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );

    double owedToMe = 0;
    double iOwe = 0;
    double totalAmount = 0;
    double totalPaid = 0;
    double totalLent = 0;
    double totalBorrowed = 0;
    int pendingCount = 0;
    int partialCount = 0;
    int settledCount = 0;

    for (final row in rows) {
      final type = row['type']?.toString() ?? '';
      final remaining = (row['remaining'] as num?)?.toDouble() ?? 0;
      final total = (row['total_amount'] as num?)?.toDouble() ?? 0;
      final paid = (row['paid_amount'] as num?)?.toDouble() ?? 0;
      final status = row['status']?.toString() ?? 'pending';

      totalAmount += total;
      totalPaid += paid;

      if (type == 'lent') {
        totalLent += total;
      } else if (type == 'borrowed') {
        totalBorrowed += total;
      }

      switch (status) {
        case 'partial':
          partialCount++;
          break;
        case 'settled':
          settledCount++;
          break;
        default:
          pendingCount++;
      }

      if (status == 'settled') {
        continue;
      }

      if (type == 'lent') {
        owedToMe += remaining;
      } else if (type == 'borrowed') {
        iOwe += remaining;
      }
    }

    return DebtLocalSummary(
      owedToMe: owedToMe,
      iOwe: iOwe,
      netPosition: owedToMe - iOwe,
      recoveryRate: totalAmount == 0 ? 0 : totalPaid / totalAmount,
      pendingCount: pendingCount,
      partialCount: partialCount,
      settledCount: settledCount,
      totalLent: totalLent,
      totalBorrowed: totalBorrowed,
    );
  }

  Future<bool> hasAnyDebtsForUser(String userId) async {
    final result = await _database.rawQuery(
      '''
        SELECT COUNT(*) AS total
        FROM $debtsTableName
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