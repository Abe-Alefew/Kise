import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';

GoalEntity _base({
  double currentAmount = 300,
  double targetAmount = 1000,
  double progress = 0.3,
  bool isCompleted = false,
  bool isLocked = false,
  String period = 'monthly',
}) =>
    GoalEntity(
      id: 'goal-001',
      title: 'Buy a Laptop',
      period: period,
      dueDate: '2025-12-31',
      dueDateDisplay: 'Due Tue Dec 31 2025',
      currentAmount: currentAmount,
      targetAmount: targetAmount,
      progress: progress,
      isCompleted: isCompleted,
      isLocked: isLocked,
      status: 'active',
    );

void main() {
  // ────────────────────────────────────────────────────
  // Basic construction & properties
  // ────────────────────────────────────────────────────
  group('GoalEntity construction', () {
    test('stores all required fields', () {
      final g = _base();
      expect(g.id, 'goal-001');
      expect(g.title, 'Buy a Laptop');
      expect(g.period, 'monthly');
      expect(g.dueDate, '2025-12-31');
      expect(g.currentAmount, 300.0);
      expect(g.targetAmount, 1000.0);
    });

    test('isDirty defaults to false', () {
      expect(_base().isDirty, isFalse);
    });

    test('optional fields default to null', () {
      final g = _base();
      expect(g.note, isNull);
      expect(g.completedAt, isNull);
      expect(g.createdAt, isNull);
      expect(g.syncError, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // Computed getters
  // ────────────────────────────────────────────────────
  group('GoalEntity computed getters', () {
    test('dueDateLabel equals dueDateDisplay', () {
      final g = _base();
      expect(g.dueDateLabel, g.dueDateDisplay);
    });

    test('periodLabel capitalizes "monthly" to "Monthly"', () {
      expect(_base(period: 'monthly').periodLabel, 'Monthly');
    });

    test('periodLabel capitalizes "daily" to "Daily"', () {
      expect(_base(period: 'daily').periodLabel, 'Daily');
    });

    test('periodLabel converts "one-time" to "One-time"', () {
      expect(_base(period: 'one-time').periodLabel, 'One-time');
    });

    test('periodLabel returns empty string for empty period', () {
      expect(_base(period: '').periodLabel, '');
    });

    test('progressPercentage clamps at 0.0 for negative progress', () {
      final g = _base(progress: -0.5);
      expect(g.progressPercentage, 0.0);
    });

    test('progressPercentage clamps at 1.0 for progress > 1', () {
      final g = _base(progress: 1.5);
      expect(g.progressPercentage, 1.0);
    });

    test('progressPercentage returns exact value in [0,1]', () {
      final g = _base(progress: 0.75);
      expect(g.progressPercentage, 0.75);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalEntity.fromJson
  // ────────────────────────────────────────────────────
  group('GoalEntity.fromJson', () {
    final json = {
      'id': 'g-abc',
      'title': 'Emergency Fund',
      'period': 'Monthly',
      'dueDate': '2026-01-01',
      'dueDateDisplay': 'Due Thu Jan 1 2026',
      'currentAmount': 500,
      'targetAmount': 2000,
      'progress': 0.25,
      'isCompleted': false,
      'isLocked': false,
      'status': 'active',
    };

    test('parses id and title', () {
      final g = GoalEntity.fromJson(json);
      expect(g.id, 'g-abc');
      expect(g.title, 'Emergency Fund');
    });

    test('normalizes period to lowercase', () {
      final g = GoalEntity.fromJson(json); // period = 'Monthly'
      expect(g.period, 'monthly');
    });

    test('parses amounts as doubles', () {
      final g = GoalEntity.fromJson(json);
      expect(g.currentAmount, 500.0);
      expect(g.targetAmount, 2000.0);
    });

    test('uses provided progress value', () {
      final g = GoalEntity.fromJson(json);
      expect(g.progress, 0.25);
    });

    test('computes progress when not provided', () {
      final noProgress = Map<String, dynamic>.from(json)
        ..remove('progress');
      final g = GoalEntity.fromJson(noProgress);
      // current=500, target=2000 → 0.25
      expect(g.progress, closeTo(0.25, 0.001));
    });

    test('handles string amounts', () {
      final strAmounts = Map<String, dynamic>.from(json)
        ..['currentAmount'] = '750'
        ..['targetAmount'] = '3000';
      final g = GoalEntity.fromJson(strAmounts);
      expect(g.currentAmount, 750.0);
      expect(g.targetAmount, 3000.0);
    });

    test('defaults isDirty to false', () {
      final g = GoalEntity.fromJson(json);
      expect(g.isDirty, isFalse);
    });

    test('defaults period to "monthly" when missing', () {
      final noperiod = Map<String, dynamic>.from(json)..remove('period');
      final g = GoalEntity.fromJson(noperiod);
      expect(g.period, 'monthly');
    });

    test('progress is 0 when target is 0 (division guard)', () {
      final zeroTarget = Map<String, dynamic>.from(json)
        ..remove('progress')
        ..['targetAmount'] = 0;
      final g = GoalEntity.fromJson(zeroTarget);
      expect(g.progress, 0.0);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalEntity.toJson / round-trip
  // ────────────────────────────────────────────────────
  group('GoalEntity.toJson', () {
    test('includes all required fields', () {
      final g = _base();
      final json = g.toJson();
      expect(json['id'], 'goal-001');
      expect(json['title'], 'Buy a Laptop');
      expect(json['period'], 'monthly');
      expect(json['currentAmount'], 300.0);
      expect(json['targetAmount'], 1000.0);
    });

    test('round-trip preserves isCompleted and isLocked', () {
      final g = _base(isCompleted: true, isLocked: true);
      final restored = GoalEntity.fromJson(g.toJson());
      expect(restored.isCompleted, isTrue);
      expect(restored.isLocked, isTrue);
    });

    test('round-trip preserves progress', () {
      final g = _base(progress: 0.42);
      final restored = GoalEntity.fromJson(g.toJson());
      expect(restored.progress, closeTo(0.42, 0.001));
    });

    test('omits null note', () {
      final g = _base();
      expect(g.toJson().containsKey('note'), isFalse);
    });

    test('includes note when present', () {
      final g = GoalEntity(
        id: 'g',
        title: 'Test',
        period: 'monthly',
        dueDate: '2025-12-31',
        dueDateDisplay: 'Dec 31',
        currentAmount: 0,
        targetAmount: 100,
        progress: 0,
        isCompleted: false,
        isLocked: false,
        status: 'active',
        note: 'save every month',
      );
      expect(g.toJson()['note'], 'save every month');
    });
  });

  // ────────────────────────────────────────────────────
  // GoalEntity.copyWith
  // ────────────────────────────────────────────────────
  group('GoalEntity.copyWith', () {
    test('preserves all fields when no args', () {
      final g = _base();
      final copy = g.copyWith();
      expect(copy.id, g.id);
      expect(copy.title, g.title);
      expect(copy.progress, g.progress);
    });

    test('updates title only', () {
      final copy = _base().copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.targetAmount, 1000.0);
    });

    test('can mark as dirty', () {
      final copy = _base().copyWith(isDirty: true);
      expect(copy.isDirty, isTrue);
    });

    test('clearSyncError sets syncError to null', () {
      final g = _base().copyWith(syncError: 'error');
      final cleared = g.copyWith(clearSyncError: true);
      expect(cleared.syncError, isNull);
    });

    test('can update isCompleted and isLocked independently', () {
      final copy = _base().copyWith(isCompleted: true, isLocked: true);
      expect(copy.isCompleted, isTrue);
      expect(copy.isLocked, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDepositEntity
  // ────────────────────────────────────────────────────
  group('GoalDepositEntity', () {
    const deposit = GoalDepositEntity(
      id: 'dep-1',
      goalId: 'goal-001',
      amount: 100.0,
      source: 'cash',
      depositedAt: '2025-06-01',
    );

    test('stores required fields', () {
      expect(deposit.id, 'dep-1');
      expect(deposit.goalId, 'goal-001');
      expect(deposit.amount, 100.0);
      expect(deposit.source, 'cash');
      expect(deposit.depositedAt, '2025-06-01');
    });

    test('isDirty defaults to false', () {
      expect(deposit.isDirty, isFalse);
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'dep-2',
        'goalId': 'goal-abc',
        'amount': 250,
        'source': 'bank',
        'depositedAt': '2025-07-01',
        'createdAt': '2025-07-01T10:00:00Z',
      };
      final d = GoalDepositEntity.fromJson(json);
      expect(d.id, 'dep-2');
      expect(d.goalId, 'goal-abc');
      expect(d.amount, 250.0);
      expect(d.source, 'bank');
      expect(d.createdAt, '2025-07-01T10:00:00Z');
    });

    test('toJson includes required fields', () {
      final json = deposit.toJson();
      expect(json['id'], 'dep-1');
      expect(json['goalId'], 'goal-001');
      expect(json['amount'], 100.0);
      expect(json['source'], 'cash');
      expect(json['depositedAt'], '2025-06-01');
    });

    test('copyWith updates amount', () {
      final copy = deposit.copyWith(amount: 200);
      expect(copy.amount, 200.0);
      expect(copy.id, 'dep-1');
    });

    test('clearSyncError removes syncError', () {
      final dirty = deposit.copyWith(syncError: 'fail');
      final cleared = dirty.copyWith(clearSyncError: true);
      expect(cleared.syncError, isNull);
    });
  });
}
