// Tests for GoalCacheDao — CRUD, status filters, deposit management,
// soft-delete, dirty tracking, and sync metadata.

import 'package:flutter_test/flutter_test.dart';

import 'package:kise/core/database/daos/goal_cache_dao.dart';

import '../../../../helpers/database_helper.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _userId = 'user-test-001';
const _now = '2025-06-01T00:00:00.000Z';

Map<String, dynamic> _goalRow({
  String id = 'goal-001',
  String title = 'Laptop Fund',
  String status = 'active',
  double target = 1000.0,
  double current = 300.0,
  int isDirty = 0,
  int isDeleted = 0,
  String period = 'monthly',
  String dueDate = '2025-12-31',
  int isCompleted = 0,
  int isLocked = 0,
}) {
  final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  return {
    'id': id,
    'user_id': _userId,
    'title': title,
    'period': period,
    'target_amount': target,
    'current_amount': current,
    'due_date': dueDate,
    'due_date_display': 'Due Wed Dec 31 2025',
    'note': null,
    'status': status,
    'is_locked': isLocked,
    'is_completed': isCompleted,
    'progress': progress,
    'completed_at': null,
    'is_dirty': isDirty,
    'is_deleted': isDeleted,
    'server_updated_at': _now,
    'synced_at': _now,
    'created_at': _now,
    'updated_at': _now,
  };
}

Map<String, dynamic> _depositRow({
  String id = 'dep-001',
  String goalId = 'goal-001',
  double amount = 100.0,
  int isDirty = 0,
}) =>
    {
      'id': id,
      'goal_id': goalId,
      'user_id': _userId,
      'amount': amount,
      'source': 'cash',
      'account_id': null,
      'deposited_at': '2025-07-01',
      'is_dirty': isDirty,
      'is_deleted': 0,
      'server_updated_at': _now,
      'synced_at': _now,
      'created_at': _now,
    };

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late GoalCacheDao dao;

  setUp(() async {
    final db = await openTestDb(
      onCreate: (db) => GoalCacheDao.ensureSchema(db),
    );
    dao = GoalCacheDao(db);
  });

  // ────────────────────────────────────────────────────
  // upsertGoal / findGoalById
  // ────────────────────────────────────────────────────
  group('upsertGoal / findGoalById', () {
    test('inserts a goal and retrieves it by id', () async {
      await dao.upsertGoal(_goalRow());

      final row = await dao.findGoalById(_userId, 'goal-001');
      expect(row, isNotNull);
      expect(row!['title'], 'Laptop Fund');
      expect(row['target_amount'], 1000.0);
      expect(row['current_amount'], 300.0);
      expect(row['status'], 'active');
    });

    test('returns null for non-existent goal id', () async {
      final row = await dao.findGoalById(_userId, 'no-such-goal');
      expect(row, isNull);
    });

    test('upsert replaces existing goal on primary key conflict', () async {
      await dao.upsertGoal(_goalRow(title: 'Old Title'));
      await dao.upsertGoal(_goalRow(title: 'New Title', current: 500));

      final row = await dao.findGoalById(_userId, 'goal-001');
      expect(row!['title'], 'New Title');
      expect(row['current_amount'], 500.0);
    });
  });

  // ────────────────────────────────────────────────────
  // upsertGoals (batch)
  // ────────────────────────────────────────────────────
  group('upsertGoals', () {
    test('inserts multiple goals in a single batch', () async {
      await dao.upsertGoals([
        _goalRow(id: 'g1', title: 'Goal 1'),
        _goalRow(id: 'g2', title: 'Goal 2'),
        _goalRow(id: 'g3', title: 'Goal 3'),
      ]);

      final rows = await dao.queryGoals(userId: _userId);
      expect(rows, hasLength(3));
    });

    test('upsertGoals with empty list does not throw', () async {
      await expectLater(dao.upsertGoals([]), completes);
    });
  });

  // ────────────────────────────────────────────────────
  // queryGoals — status filters
  // ────────────────────────────────────────────────────
  group('queryGoals filters', () {
    setUp(() async {
      // active: status='active', current < target
      await dao.upsertGoal(_goalRow(
          id: 'g1', status: 'active', target: 1000, current: 300));
      // completed by status
      await dao.upsertGoal(_goalRow(
          id: 'g2', status: 'completed', target: 500, current: 500,
          isCompleted: 1));
      // completed by amount (current >= target)
      await dao.upsertGoal(_goalRow(
          id: 'g3', status: 'active', target: 200, current: 200));
      // canceled
      await dao.upsertGoal(_goalRow(
          id: 'g4', status: 'canceled', target: 400, current: 0));
    });

    test('"all" returns every non-deleted goal', () async {
      final rows = await dao.queryGoals(userId: _userId, status: 'all');
      expect(rows, hasLength(4));
    });

    test('"active" returns only active goals with current < target', () async {
      final rows = await dao.queryGoals(userId: _userId, status: 'active');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'g1');
    });

    test('"completed" returns goals with status=completed OR current>=target',
        () async {
      final rows = await dao.queryGoals(userId: _userId, status: 'completed');
      // g2 (status=completed) + g3 (current >= target)
      expect(rows, hasLength(2));
      final ids = rows.map((r) => r['id']).toSet();
      expect(ids, containsAll(['g2', 'g3']));
    });

    test('"canceled" returns only canceled goals', () async {
      final rows = await dao.queryGoals(userId: _userId, status: 'canceled');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'g4');
    });

    test('excludes soft-deleted goals by default', () async {
      await dao.upsertGoal(_goalRow(id: 'g5', isDeleted: 1));
      final rows = await dao.queryGoals(userId: _userId);
      expect(rows.any((r) => r['id'] == 'g5'), isFalse);
    });

    test('includeDeleted=true returns soft-deleted goals', () async {
      await dao.upsertGoal(_goalRow(id: 'g5', isDeleted: 1));
      final rows =
          await dao.queryGoals(userId: _userId, includeDeleted: true);
      expect(rows.any((r) => r['id'] == 'g5'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // deleteGoalById / softDeleteGoalById
  // ────────────────────────────────────────────────────
  group('deleteGoalById', () {
    test('hard-deletes the goal row', () async {
      await dao.upsertGoal(_goalRow());
      await dao.deleteGoalById(_userId, 'goal-001');

      expect(await dao.findGoalById(_userId, 'goal-001'), isNull);
    });
  });

  group('softDeleteGoalById', () {
    test('marks is_deleted=1 and is_dirty=1', () async {
      await dao.upsertGoal(_goalRow());
      await dao.softDeleteGoalById(_userId, 'goal-001');

      final row = await dao.findGoalById(_userId, 'goal-001');
      expect(row!['is_deleted'], 1);
      expect(row['is_dirty'], 1);
    });

    test('soft-deleted goal is hidden from default queryGoals', () async {
      await dao.upsertGoal(_goalRow());
      await dao.softDeleteGoalById(_userId, 'goal-001');

      final rows = await dao.queryGoals(userId: _userId);
      expect(rows, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // Deposits
  // ────────────────────────────────────────────────────
  group('upsertDeposit / queryDepositsForGoal', () {
    setUp(() async {
      await dao.upsertGoal(_goalRow());
    });

    test('inserts and retrieves a deposit', () async {
      await dao.upsertDeposit(_depositRow());

      final deposits = await dao.queryDepositsForGoal(
          userId: _userId, goalId: 'goal-001');
      expect(deposits, hasLength(1));
      expect(deposits.first['amount'], 100.0);
    });

    test('multiple deposits for the same goal are all returned', () async {
      await dao.upsertDeposit(_depositRow(id: 'd1', amount: 50));
      await dao.upsertDeposit(_depositRow(id: 'd2', amount: 150));

      final deposits = await dao.queryDepositsForGoal(
          userId: _userId, goalId: 'goal-001');
      expect(deposits, hasLength(2));
    });

    test('deleteDepositById removes the deposit', () async {
      await dao.upsertDeposit(_depositRow());
      await dao.deleteDepositById(_userId, 'dep-001');

      final deposits = await dao.queryDepositsForGoal(
          userId: _userId, goalId: 'goal-001');
      expect(deposits, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // replaceAllGoalsForUser
  // ────────────────────────────────────────────────────
  group('replaceAllGoalsForUser', () {
    test('replaces non-dirty goals with new set', () async {
      await dao.upsertGoal(_goalRow(id: 'old-1'));
      await dao.upsertGoal(_goalRow(id: 'old-2'));

      await dao.replaceAllGoalsForUser(
          _userId, [_goalRow(id: 'new-1', title: 'New Goal')]);

      final rows = await dao.queryGoals(userId: _userId);
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'new-1');
    });

    test('dirty goals survive replaceAllGoalsForUser', () async {
      await dao.upsertGoal(_goalRow(id: 'dirty', isDirty: 1));
      await dao.replaceAllGoalsForUser(_userId, []);

      final rows = await dao.queryGoals(userId: _userId);
      expect(rows.any((r) => r['id'] == 'dirty'), isTrue);
    });

    test('replaceDepositsForGoal preserves dirty deposits', () async {
      await dao.upsertGoal(_goalRow());
      await dao.upsertDeposit(_depositRow(id: 'd-dirty', isDirty: 1));

      await dao.replaceDepositsForGoal(_userId, 'goal-001', []);

      final deposits = await dao.queryDepositsForGoal(
          userId: _userId, goalId: 'goal-001', includeDeleted: true);
      expect(deposits.any((r) => r['id'] == 'd-dirty'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // getDirtyGoals / getDirtyDeposits
  // ────────────────────────────────────────────────────
  group('getDirtyGoals / getDirtyDeposits', () {
    test('getDirtyGoals returns only dirty non-deleted goals', () async {
      await dao.upsertGoal(_goalRow(id: 'clean', isDirty: 0));
      await dao.upsertGoal(_goalRow(id: 'dirty', isDirty: 1));

      final dirty = await dao.getDirtyGoals(_userId);
      expect(dirty, hasLength(1));
      expect(dirty.first['id'], 'dirty');
    });

    test('getDirtyDeposits returns only dirty non-deleted deposits', () async {
      await dao.upsertGoal(_goalRow());
      await dao.upsertDeposit(_depositRow(id: 'clean', isDirty: 0));
      await dao.upsertDeposit(_depositRow(id: 'dirty', isDirty: 1));

      final dirty = await dao.getDirtyDeposits(_userId);
      expect(dirty, hasLength(1));
      expect(dirty.first['id'], 'dirty');
    });
  });

  // ────────────────────────────────────────────────────
  // hasAnyGoalsForUser
  // ────────────────────────────────────────────────────
  group('hasAnyGoalsForUser', () {
    test('returns false on empty database', () async {
      expect(await dao.hasAnyGoalsForUser(_userId), isFalse);
    });

    test('returns true after inserting a goal', () async {
      await dao.upsertGoal(_goalRow());
      expect(await dao.hasAnyGoalsForUser(_userId), isTrue);
    });

    test('returns false when all goals are soft-deleted', () async {
      await dao.upsertGoal(_goalRow(isDeleted: 1));
      expect(await dao.hasAnyGoalsForUser(_userId), isFalse);
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
      final ts = DateTime.utc(2025, 6, 15, 10, 30);
      await dao.setLastSyncAt(ts);

      final retrieved = await dao.getLastSyncAt();
      expect(retrieved, isNotNull);
      expect(retrieved!.year, 2025);
      expect(retrieved.month, 6);
      expect(retrieved.day, 15);
    });

    test('second setLastSyncAt overwrites the first', () async {
      await dao.setLastSyncAt(DateTime.utc(2025, 1, 1));
      await dao.setLastSyncAt(DateTime.utc(2025, 12, 31));

      final ts = await dao.getLastSyncAt();
      expect(ts!.month, 12);
    });
  });

  // ────────────────────────────────────────────────────
  // clearAllForUser
  // ────────────────────────────────────────────────────
  group('clearAllForUser', () {
    test('removes all goals and deposits for the user', () async {
      await dao.upsertGoal(_goalRow());
      await dao.upsertDeposit(_depositRow());

      await dao.clearAllForUser(_userId);

      final goals = await dao.queryGoals(userId: _userId, includeDeleted: true);
      expect(goals, isEmpty);
    });

    test('does not throw on empty database', () async {
      await expectLater(dao.clearAllForUser(_userId), completes);
    });
  });
}
