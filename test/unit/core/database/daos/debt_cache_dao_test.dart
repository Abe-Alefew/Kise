import 'package:flutter_test/flutter_test.dart';

import 'package:kise/core/database/daos/debt_cache_dao.dart';

import '../../../../helpers/database_helper.dart';



const _userId = 'user-test-001';
const _syncedAt = '2025-06-01T00:00:00.000Z';
const _now = '2025-06-01T00:00:00.000Z';

Map<String, dynamic> _debtRow({
  String id = 'debt-001',
  String personName = 'Alice',
  String type = 'lent',
  double total = 1000.0,
  double paid = 0.0,
  String status = 'pending',
  int isDirty = 0,
  int isDeleted = 0,
  String debtDate = '2025-06-01',
}) =>
    {
      'id': id,
      'user_id': _userId,
      'person_name': personName,
      'person_initial': personName.isNotEmpty ? personName[0].toUpperCase() : '?',
      'type': type,
      'total_amount': total,
      'paid_amount': paid,
      'remaining': (total - paid).clamp(0.0, double.infinity),
      'status': status,
      'debt_date': debtDate,
      'notes': null,
      'is_dirty': isDirty,
      'is_deleted': isDeleted,
      'server_updated_at': _syncedAt,
      'synced_at': _syncedAt,
      'created_at': _now,
      'updated_at': _now,
    };

Map<String, dynamic> _paymentRow({
  String id = 'pay-001',
  String debtId = 'debt-001',
  double amount = 200.0,
  int isDirty = 0,
}) =>
    {
      'id': id,
      'debt_id': debtId,
      'user_id': _userId,
      'amount': amount,
      'payment_date': '2025-07-01',
      'notes': null,
      'is_dirty': isDirty,
      'is_deleted': 0,
      'server_updated_at': _syncedAt,
      'synced_at': _syncedAt,
      'created_at': _now,
    };



void main() {
  late DebtCacheDao dao;

  setUp(() async {
    final db = await openTestDb(
      onCreate: (db) => DebtCacheDao.ensureSchema(db),
    );
    dao = DebtCacheDao(db);
  });

  
  
  
  group('upsertDebt / findDebtById', () {
    test('inserts a debt and retrieves it by id', () async {
      await dao.upsertDebt(_debtRow());

      final row = await dao.findDebtById(_userId, 'debt-001');
      expect(row, isNotNull);
      expect(row!['person_name'], 'Alice');
      expect(row['type'], 'lent');
      expect(row['total_amount'], 1000.0);
    });

    test('returns null for non-existent debt id', () async {
      final row = await dao.findDebtById(_userId, 'no-such-debt');
      expect(row, isNull);
    });

    test('upsert replaces existing row on primary key conflict', () async {
      await dao.upsertDebt(_debtRow(personName: 'Original'));
      await dao.upsertDebt(_debtRow(personName: 'Updated', paid: 500));

      final row = await dao.findDebtById(_userId, 'debt-001');
      expect(row!['person_name'], 'Updated');
      expect(row['paid_amount'], 500.0);
    });
  });

  
  
  
  group('queryDebts filters', () {
    setUp(() async {
      await dao.upsertDebt(_debtRow(
          id: 'd1', type: 'lent', status: 'pending', total: 500, paid: 0));
      await dao.upsertDebt(_debtRow(
          id: 'd2', type: 'borrowed', status: 'partial', total: 800, paid: 300));
      await dao.upsertDebt(_debtRow(
          id: 'd3', type: 'lent', status: 'settled', total: 200, paid: 200));
      await dao.upsertDebt(_debtRow(
          id: 'd4', type: 'borrowed', status: 'pending', total: 400, paid: 0));
    });

    test('"all" filter returns all non-deleted debts', () async {
      final rows = await dao.queryDebts(userId: _userId, filter: 'all');
      expect(rows, hasLength(4));
    });

    test('"lent" filter returns only lent debts', () async {
      final rows = await dao.queryDebts(userId: _userId, filter: 'lent');
      expect(rows, hasLength(2));
      expect(rows.every((r) => r['type'] == 'lent'), isTrue);
    });

    test('"borrowed" filter returns only borrowed debts', () async {
      final rows = await dao.queryDebts(userId: _userId, filter: 'borrowed');
      expect(rows, hasLength(2));
      expect(rows.every((r) => r['type'] == 'borrowed'), isTrue);
    });

    test('"settled" filter returns only settled debts', () async {
      final rows = await dao.queryDebts(userId: _userId, filter: 'settled');
      expect(rows, hasLength(1));
      expect(rows.first['status'], 'settled');
    });

    test('"active" filter excludes settled debts', () async {
      final rows = await dao.queryDebts(userId: _userId, filter: 'active');
      expect(rows, hasLength(3)); 
      expect(rows.every((r) => r['status'] != 'settled'), isTrue);
    });

    test('excludes deleted debts by default', () async {
      await dao.upsertDebt(
          _debtRow(id: 'd5', isDeleted: 1, type: 'lent', status: 'pending'));
      final rows = await dao.queryDebts(userId: _userId, filter: 'all');
      expect(rows.any((r) => r['id'] == 'd5'), isFalse);
    });

    test('includeDeleted=true returns soft-deleted rows', () async {
      await dao.upsertDebt(
          _debtRow(id: 'd5', isDeleted: 1, type: 'lent', status: 'pending'));
      final rows = await dao.queryDebts(
          userId: _userId, filter: 'all', includeDeleted: true);
      expect(rows.any((r) => r['id'] == 'd5'), isTrue);
    });

    test('queryDebts for another userId returns empty list', () async {
      final rows = await dao.queryDebts(userId: 'other-user', filter: 'all');
      expect(rows, isEmpty);
    });
  });

  
  
  
  group('deleteDebtById', () {
    test('hard-deletes the debt row', () async {
      await dao.upsertDebt(_debtRow());
      await dao.deleteDebtById(_userId, 'debt-001');
      expect(await dao.findDebtById(_userId, 'debt-001'), isNull);
    });

    test('does not throw when deleting non-existent id', () async {
      await expectLater(
          dao.deleteDebtById(_userId, 'ghost-id'), completes);
    });
  });

  group('softDeleteDebtById', () {
    test('marks is_deleted=1 and is_dirty=1', () async {
      await dao.upsertDebt(_debtRow());
      await dao.softDeleteDebtById(_userId, 'debt-001');

      final row = await dao.findDebtById(_userId, 'debt-001');
      expect(row!['is_deleted'], 1);
      expect(row['is_dirty'], 1);
    });

    test('soft-deleted debt is hidden from default queryDebts', () async {
      await dao.upsertDebt(_debtRow());
      await dao.softDeleteDebtById(_userId, 'debt-001');
      final rows = await dao.queryDebts(userId: _userId);
      expect(rows, isEmpty);
    });
  });

  
  
  
  group('upsertPayment / queryPaymentsForDebt', () {
    setUp(() async {
      await dao.upsertDebt(_debtRow());
    });

    test('inserts and retrieves a payment for a debt', () async {
      await dao.upsertPayment(_paymentRow());

      final payments = await dao.queryPaymentsForDebt(
          userId: _userId, debtId: 'debt-001');
      expect(payments, hasLength(1));
      expect(payments.first['amount'], 200.0);
    });

    test('multiple payments are all returned', () async {
      await dao.upsertPayment(_paymentRow(id: 'p1', amount: 100));
      await dao.upsertPayment(_paymentRow(id: 'p2', amount: 200));

      final payments = await dao.queryPaymentsForDebt(
          userId: _userId, debtId: 'debt-001');
      expect(payments, hasLength(2));
    });

    test('deletePaymentById hard-deletes the payment', () async {
      await dao.upsertPayment(_paymentRow());
      await dao.deletePaymentById(_userId, 'pay-001');

      final payments = await dao.queryPaymentsForDebt(
          userId: _userId, debtId: 'debt-001');
      expect(payments, isEmpty);
    });
  });

  
  
  
  group('replaceAllDebtsForUser', () {
    test('replaces non-dirty debts with new rows', () async {
      await dao.upsertDebt(_debtRow(id: 'old-1'));
      await dao.upsertDebt(_debtRow(id: 'old-2'));

      await dao.replaceAllDebtsForUser(
        _userId,
        [_debtRow(id: 'new-1', personName: 'New')],
        [],
      );

      final rows = await dao.queryDebts(userId: _userId);
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'new-1');
    });

    test('preserves dirty debts during replace', () async {
      await dao.upsertDebt(_debtRow(id: 'dirty-1', isDirty: 1));
      await dao.replaceAllDebtsForUser(_userId, [], []);

      final rows = await dao.queryDebts(userId: _userId);
      expect(rows.any((r) => r['id'] == 'dirty-1'), isTrue);
    });
  });

  
  
  
  group('computeLocalSummary', () {
    test('returns zeros for empty database', () async {
      final summary = await dao.computeLocalSummary(_userId);
      expect(summary.owedToMe, 0.0);
      expect(summary.iOwe, 0.0);
      expect(summary.netPosition, 0.0);
      expect(summary.recoveryRate, 0.0);
    });

    test('calculates owedToMe from pending lent debts', () async {
      await dao.upsertDebt(_debtRow(
          id: 'l1', type: 'lent', status: 'pending', total: 500, paid: 0));
      await dao.upsertDebt(_debtRow(
          id: 'l2', type: 'lent', status: 'partial', total: 800, paid: 300));

      final summary = await dao.computeLocalSummary(_userId);
      
      expect(summary.owedToMe, 1000.0);
    });

    test('calculates iOwe from pending borrowed debts', () async {
      await dao.upsertDebt(_debtRow(
          id: 'b1',
          type: 'borrowed',
          status: 'pending',
          total: 400,
          paid: 0));

      final summary = await dao.computeLocalSummary(_userId);
      expect(summary.iOwe, 400.0);
    });

    test('excludes settled debts from owedToMe/iOwe', () async {
      await dao.upsertDebt(_debtRow(
          id: 'settled', type: 'lent', status: 'settled', total: 300, paid: 300));

      final summary = await dao.computeLocalSummary(_userId);
      expect(summary.owedToMe, 0.0);
    });

    test('netPosition = owedToMe - iOwe', () async {
      await dao.upsertDebt(_debtRow(
          id: 'l', type: 'lent', status: 'pending', total: 1000, paid: 0));
      await dao.upsertDebt(_debtRow(
          id: 'b', type: 'borrowed', status: 'pending', total: 400, paid: 0));

      final summary = await dao.computeLocalSummary(_userId);
      expect(summary.netPosition, closeTo(600.0, 0.001));
    });

    test('counts are correct for pending/partial/settled', () async {
      await dao.upsertDebt(_debtRow(
          id: 'p', type: 'lent', status: 'pending', total: 100, paid: 0));
      await dao.upsertDebt(_debtRow(
          id: 'pa', type: 'lent', status: 'partial', total: 200, paid: 50));
      await dao.upsertDebt(_debtRow(
          id: 's', type: 'lent', status: 'settled', total: 300, paid: 300));

      final summary = await dao.computeLocalSummary(_userId);
      expect(summary.pendingCount, 1);
      expect(summary.partialCount, 1);
      expect(summary.settledCount, 1);
    });

    test('recoveryRate = totalPaid / totalAmount', () async {
      await dao.upsertDebt(_debtRow(
          id: 'r1', type: 'lent', status: 'partial', total: 1000, paid: 400));
      await dao.upsertDebt(_debtRow(
          id: 'r2', type: 'borrowed', status: 'pending', total: 500, paid: 0));

      final summary = await dao.computeLocalSummary(_userId);
      
      expect(summary.recoveryRate, closeTo(0.267, 0.001));
    });
  });

  
  
  
  group('getDirtyDebts / clearDirtyEntriesForUser', () {
    test('getDirtyDebts returns only dirty non-deleted rows', () async {
      await dao.upsertDebt(_debtRow(id: 'd1', isDirty: 1));
      await dao.upsertDebt(_debtRow(id: 'd2', isDirty: 0));

      final dirty = await dao.getDirtyDebts(_userId);
      expect(dirty, hasLength(1));
      expect(dirty.first['id'], 'd1');
    });

    test('clearDirtyEntriesForUser removes all dirty rows', () async {
      await dao.upsertDebt(_debtRow(id: 'dirty', isDirty: 1));
      await dao.clearDirtyEntriesForUser(_userId);

      final dirty = await dao.getDirtyDebts(_userId);
      expect(dirty, isEmpty);
    });
  });

  
  
  
  group('hasAnyDebtsForUser', () {
    test('returns false for empty database', () async {
      expect(await dao.hasAnyDebtsForUser(_userId), isFalse);
    });

    test('returns true after inserting a debt', () async {
      await dao.upsertDebt(_debtRow());
      expect(await dao.hasAnyDebtsForUser(_userId), isTrue);
    });

    test('returns false when only soft-deleted debts exist', () async {
      await dao.upsertDebt(_debtRow(isDeleted: 1));
      expect(await dao.hasAnyDebtsForUser(_userId), isFalse);
    });
  });

  
  
  
  group('getLastSyncAt / setLastSyncAt', () {
    test('returns null when no sync has been recorded', () async {
      final ts = await dao.getLastSyncAt();
      expect(ts, isNull);
    });

    test('stores and retrieves sync timestamp', () async {
      final now = DateTime.utc(2025, 6, 15, 12, 0, 0);
      await dao.setLastSyncAt(now);

      final ts = await dao.getLastSyncAt();
      expect(ts, isNotNull);
      expect(ts!.year, 2025);
      expect(ts.month, 6);
      expect(ts.day, 15);
    });

    test('overwrites previous sync timestamp on second call', () async {
      await dao.setLastSyncAt(DateTime.utc(2025, 1, 1));
      await dao.setLastSyncAt(DateTime.utc(2025, 6, 15));

      final ts = await dao.getLastSyncAt();
      expect(ts!.month, 6);
    });
  });

  
  
  
  group('clearAllForUser', () {
    test('removes all debts and payments for the given user', () async {
      await dao.upsertDebt(_debtRow());
      await dao.upsertPayment(_paymentRow());

      await dao.clearAllForUser(_userId);

      final rows = await dao.queryDebts(userId: _userId, includeDeleted: true);
      expect(rows, isEmpty);
    });

    test('does not remove debts belonging to another user', () async {
      await dao.upsertDebt(_debtRow());
      await dao.upsertDebt(_debtRow(id: 'other-debt')
        ..['user_id'] = 'other-user');

      await dao.clearAllForUser(_userId);

      
      
      final rows = await dao.queryDebts(userId: _userId, includeDeleted: true);
      expect(rows, isEmpty);
    });
  });
}
