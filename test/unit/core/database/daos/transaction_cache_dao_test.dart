// Tests for TransactionCacheDao — CRUD, type/category/date/search filters,
// sort orders, pagination, soft-delete, dirty tracking, and sync metadata.

import 'package:flutter_test/flutter_test.dart';

import 'package:kise/core/database/daos/transaction_cache_dao.dart';

import '../../../../helpers/database_helper.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _userId = 'user-test-001';
const _now = '2025-06-01T00:00:00.000Z';

Map<String, dynamic> _txRow({
  String id = 'tx-001',
  String type = 'expense',
  String title = 'Coffee',
  String category = 'Food',
  double amount = 45.0,
  String transactionDate = '2025-06-01',
  int isDirty = 0,
  int isDeleted = 0,
  String? note,
}) =>
    {
      'id': id,
      'user_id': _userId,
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'transaction_date': transactionDate,
      'display_date': 'Jun 1',
      'month_label': 'Jun',
      'account_id': null,
      'account_name': null,
      'note': note,
      'icon_key': 'circle',
      'is_dirty': isDirty,
      'is_deleted': isDeleted,
      'server_updated_at': _now,
      'synced_at': _now,
      'created_at': _now,
      'updated_at': _now,
    };

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late TransactionCacheDao dao;

  setUp(() async {
    final db = await openTestDb(
      onCreate: (db) => TransactionCacheDao.ensureSchema(db),
    );
    dao = TransactionCacheDao(db);
  });

  // ────────────────────────────────────────────────────
  // upsertOne / findById
  // ────────────────────────────────────────────────────
  group('upsertOne / findById', () {
    test('inserts a transaction and retrieves it by id', () async {
      await dao.upsertOne(_txRow());

      final row = await dao.findById(_userId, 'tx-001');
      expect(row, isNotNull);
      expect(row!['title'], 'Coffee');
      expect(row['type'], 'expense');
      expect(row['amount'], 45.0);
    });

    test('returns null for non-existent transaction id', () async {
      final row = await dao.findById(_userId, 'no-such-tx');
      expect(row, isNull);
    });

    test('upsert replaces existing row on primary key conflict', () async {
      await dao.upsertOne(_txRow(title: 'Old'));
      await dao.upsertOne(_txRow(title: 'New', amount: 90.0));

      final row = await dao.findById(_userId, 'tx-001');
      expect(row!['title'], 'New');
      expect(row['amount'], 90.0);
    });
  });

  // ────────────────────────────────────────────────────
  // upsertMany
  // ────────────────────────────────────────────────────
  group('upsertMany', () {
    test('inserts multiple transactions in a batch', () async {
      await dao.upsertMany([
        _txRow(id: 't1'),
        _txRow(id: 't2'),
        _txRow(id: 't3'),
      ]);

      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows, hasLength(3));
    });

    test('does not throw for empty list', () async {
      await expectLater(dao.upsertMany([]), completes);
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — type filter
  // ────────────────────────────────────────────────────
  group('queryTransactions type filter', () {
    setUp(() async {
      await dao.upsertOne(_txRow(id: 'e1', type: 'expense'));
      await dao.upsertOne(_txRow(id: 'e2', type: 'expense'));
      await dao.upsertOne(_txRow(id: 'i1', type: 'income'));
    });

    test('no type filter returns all non-deleted', () async {
      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows, hasLength(3));
    });

    test('type="expense" returns only expenses', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, type: 'expense');
      expect(rows, hasLength(2));
      expect(rows.every((r) => r['type'] == 'expense'), isTrue);
    });

    test('type="income" returns only income', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, type: 'income');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'i1');
    });

    test('type="All" is treated as no filter', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, type: 'All');
      expect(rows, hasLength(3));
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — category filter
  // ────────────────────────────────────────────────────
  group('queryTransactions category filter', () {
    setUp(() async {
      await dao.upsertOne(_txRow(id: 'f1', category: 'Food'));
      await dao.upsertOne(_txRow(id: 'f2', category: 'Food'));
      await dao.upsertOne(_txRow(id: 't1', category: 'Transport'));
    });

    test('category="Food" returns only Food transactions', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, category: 'Food');
      expect(rows, hasLength(2));
      expect(rows.every((r) => r['category'] == 'Food'), isTrue);
    });

    test('category="Transport" returns only Transport', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, category: 'Transport');
      expect(rows, hasLength(1));
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — date range filter
  // ────────────────────────────────────────────────────
  group('queryTransactions date range', () {
    setUp(() async {
      await dao.upsertOne(_txRow(id: 'jan', transactionDate: '2025-01-15'));
      await dao.upsertOne(_txRow(id: 'mar', transactionDate: '2025-03-20'));
      await dao.upsertOne(_txRow(id: 'jun', transactionDate: '2025-06-01'));
    });

    test('fromDate filters out earlier transactions', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, fromDate: '2025-03-01');
      expect(rows, hasLength(2)); // mar + jun
      expect(rows.any((r) => r['id'] == 'jan'), isFalse);
    });

    test('toDate filters out later transactions', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, toDate: '2025-03-31');
      expect(rows, hasLength(2)); // jan + mar
      expect(rows.any((r) => r['id'] == 'jun'), isFalse);
    });

    test('fromDate + toDate creates a closed range', () async {
      final rows = await dao.queryTransactions(
          userId: _userId,
          fromDate: '2025-02-01',
          toDate: '2025-04-30');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'mar');
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — search
  // ────────────────────────────────────────────────────
  group('queryTransactions search', () {
    setUp(() async {
      await dao.upsertOne(_txRow(id: 't1', title: 'Morning coffee'));
      await dao.upsertOne(_txRow(id: 't2', title: 'Bus fare'));
      await dao.upsertOne(
          _txRow(id: 't3', title: 'Grocery', note: 'weekly coffee shop'));
    });

    test('searchQuery matches on title', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, searchQuery: 'coffee');
      expect(rows, hasLength(2)); // t1 (title) + t3 (note)
    });

    test('searchQuery matches on note', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, searchQuery: 'weekly');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 't3');
    });

    test('empty searchQuery is ignored (no filter)', () async {
      final rows = await dao.queryTransactions(
          userId: _userId, searchQuery: '   ');
      expect(rows, hasLength(3));
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — sort orders
  // ────────────────────────────────────────────────────
  group('queryTransactions sort', () {
    setUp(() async {
      await dao.upsertOne(
          _txRow(id: 'jan', transactionDate: '2025-01-01', amount: 100));
      await dao.upsertOne(
          _txRow(id: 'jun', transactionDate: '2025-06-01', amount: 500));
      await dao.upsertOne(
          _txRow(id: 'mar', transactionDate: '2025-03-01', amount: 300));
    });

    test('default sort is date_desc (newest first)', () async {
      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows.first['id'], 'jun');
      expect(rows.last['id'], 'jan');
    });

    test('date_asc sort returns oldest first', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, sort: 'date_asc');
      expect(rows.first['id'], 'jan');
      expect(rows.last['id'], 'jun');
    });

    test('amount_desc sort returns highest amount first', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, sort: 'amount_desc');
      expect(rows.first['amount'], 500.0);
      expect(rows.last['amount'], 100.0);
    });

    test('amount_asc sort returns lowest amount first', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, sort: 'amount_asc');
      expect(rows.first['amount'], 100.0);
      expect(rows.last['amount'], 500.0);
    });
  });

  // ────────────────────────────────────────────────────
  // queryTransactions — pagination
  // ────────────────────────────────────────────────────
  group('queryTransactions pagination', () {
    setUp(() async {
      for (int i = 1; i <= 5; i++) {
        await dao.upsertOne(
            _txRow(id: 'tx-$i', transactionDate: '2025-0$i-01'));
      }
    });

    test('limit=2 returns only 2 rows', () async {
      final rows =
          await dao.queryTransactions(userId: _userId, limit: 2);
      expect(rows, hasLength(2));
    });

    test('offset skips the first N rows', () async {
      final all = await dao.queryTransactions(userId: _userId);
      final paged =
          await dao.queryTransactions(userId: _userId, limit: 2, offset: 2);
      expect(paged.first['id'], all[2]['id']);
    });
  });

  // ────────────────────────────────────────────────────
  // countTransactions
  // ────────────────────────────────────────────────────
  group('countTransactions', () {
    test('returns 0 for empty database', () async {
      final count = await dao.countTransactions(userId: _userId);
      expect(count, 0);
    });

    test('returns correct count after inserts', () async {
      await dao.upsertOne(_txRow(id: 't1'));
      await dao.upsertOne(_txRow(id: 't2'));
      expect(await dao.countTransactions(userId: _userId), 2);
    });

    test('filtered count matches filtered query', () async {
      await dao.upsertOne(_txRow(id: 'e1', type: 'expense'));
      await dao.upsertOne(_txRow(id: 'i1', type: 'income'));

      final count = await dao.countTransactions(
          userId: _userId, type: 'expense');
      expect(count, 1);
    });
  });

  // ────────────────────────────────────────────────────
  // deleteById / softDeleteById
  // ────────────────────────────────────────────────────
  group('deleteById', () {
    test('hard-deletes the transaction row', () async {
      await dao.upsertOne(_txRow());
      await dao.deleteById(_userId, 'tx-001');

      expect(await dao.findById(_userId, 'tx-001'), isNull);
    });

    test('does not throw for non-existent id', () async {
      await expectLater(dao.deleteById(_userId, 'ghost'), completes);
    });
  });

  group('softDeleteById', () {
    test('marks is_deleted=1', () async {
      await dao.upsertOne(_txRow());
      await dao.softDeleteById(_userId, 'tx-001');

      final row = await dao.findById(_userId, 'tx-001');
      expect(row!['is_deleted'], 1);
    });

    test('soft-deleted transaction excluded from default query', () async {
      await dao.upsertOne(_txRow());
      await dao.softDeleteById(_userId, 'tx-001');

      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows, isEmpty);
    });

    test('includeDeleted=true returns soft-deleted row', () async {
      await dao.upsertOne(_txRow());
      await dao.softDeleteById(_userId, 'tx-001');

      final rows = await dao.queryTransactions(
          userId: _userId, includeDeleted: true);
      expect(rows.any((r) => r['id'] == 'tx-001'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // replaceAllForUser
  // ────────────────────────────────────────────────────
  group('replaceAllForUser', () {
    test('replaces non-dirty rows with new set', () async {
      await dao.upsertOne(_txRow(id: 'old-1'));
      await dao.upsertOne(_txRow(id: 'old-2'));

      await dao.replaceAllForUser(
          _userId, [_txRow(id: 'new-1', title: 'New')]);

      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'new-1');
    });

    test('dirty rows survive replaceAllForUser', () async {
      await dao.upsertOne(_txRow(id: 'dirty', isDirty: 1));
      await dao.replaceAllForUser(_userId, []);

      final rows = await dao.queryTransactions(userId: _userId);
      expect(rows.any((r) => r['id'] == 'dirty'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // hasAnyForUser
  // ────────────────────────────────────────────────────
  group('hasAnyForUser', () {
    test('returns false on empty database', () async {
      expect(await dao.hasAnyForUser(_userId), isFalse);
    });

    test('returns true after inserting a transaction', () async {
      await dao.upsertOne(_txRow());
      expect(await dao.hasAnyForUser(_userId), isTrue);
    });

    test('returns false when only soft-deleted rows exist', () async {
      await dao.upsertOne(_txRow(isDeleted: 1));
      expect(await dao.hasAnyForUser(_userId), isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // getDirtyTransactions
  // ────────────────────────────────────────────────────
  group('getDirtyTransactions', () {
    test('returns only dirty non-deleted rows', () async {
      await dao.upsertOne(_txRow(id: 'clean', isDirty: 0));
      await dao.upsertOne(_txRow(id: 'dirty', isDirty: 1));

      final dirty = await dao.getDirtyTransactions(_userId);
      expect(dirty, hasLength(1));
      expect(dirty.first['id'], 'dirty');
    });

    test('returns empty when no dirty rows', () async {
      await dao.upsertOne(_txRow(isDirty: 0));
      expect(await dao.getDirtyTransactions(_userId), isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // getLastSyncAt / setLastSyncAt
  // ────────────────────────────────────────────────────
  group('getLastSyncAt / setLastSyncAt', () {
    test('returns null before first sync', () async {
      expect(await dao.getLastSyncAt(), isNull);
    });

    test('stores and retrieves sync timestamp', () async {
      final ts = DateTime.utc(2025, 6, 15, 8, 0);
      await dao.setLastSyncAt(ts);

      final retrieved = await dao.getLastSyncAt();
      expect(retrieved!.year, 2025);
      expect(retrieved.month, 6);
      expect(retrieved.day, 15);
    });

    test('second setLastSyncAt replaces first', () async {
      await dao.setLastSyncAt(DateTime.utc(2025, 1, 1));
      await dao.setLastSyncAt(DateTime.utc(2025, 12, 31));

      expect((await dao.getLastSyncAt())!.month, 12);
    });
  });

  // ────────────────────────────────────────────────────
  // clearAllForUser
  // ────────────────────────────────────────────────────
  group('clearAllForUser', () {
    test('removes all rows for user', () async {
      await dao.upsertMany([_txRow(id: 't1'), _txRow(id: 't2')]);
      await dao.clearAllForUser(_userId);

      final rows = await dao.queryTransactions(
          userId: _userId, includeDeleted: true);
      expect(rows, isEmpty);
    });

    test('does not throw on empty database', () async {
      await expectLater(dao.clearAllForUser(_userId), completes);
    });
  });
}
