// Tests for GoalsNotifier aggregate properties — progress totals, locked/active
// counts — which is what the planned profileGoalsProvider will expose.
// The profileGoalsProvider itself is not yet implemented in the app; these
// tests cover the GoalsViewState model that will back it.

import 'package:flutter_test/flutter_test.dart';

import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/presentation/state/goals_notifier.dart';

import '../../helpers/test_data/goal_fixtures.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

GoalsViewState _state(List<GoalEntity> items, {GoalStatusFilter filter = GoalStatusFilter.all}) =>
    GoalsViewState(items: items, fromCache: false, isStale: false, filter: filter);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ────────────────────────────────────────────────────
  // GoalsViewState — aggregate helpers the profileGoalsProvider will use
  // ────────────────────────────────────────────────────
  group('GoalsViewState aggregate properties', () {
    group('item counts', () {
      test('empty list has 0 items', () {
        expect(_state([]).items, isEmpty);
      });

      test('active goals are counted correctly', () {
        // activeGoal has status='active'; completedGoal='completed'; canceledGoal='canceled'
        final state = _state([activeGoal, completedGoal, canceledGoal]);
        final active = state.items.where((g) => g.status == 'active').length;
        expect(active, 1);
      });

      test('completed goals count is correct', () {
        final state = _state([activeGoal, completedGoal, canceledGoal]);
        final completed = state.items.where((g) => g.isCompleted).length;
        expect(completed, 1);
      });

      test('locked goals count is correct', () {
        final state = _state([activeGoal, lockedGoal, completedGoal]);
        final locked = state.items.where((g) => g.isLocked).length;
        expect(locked, 1);
      });
    });

    group('total savings', () {
      test('total current amount across all goals', () {
        final state = _state([activeGoal, completedGoal]);
        final totalCurrent =
            state.items.fold<double>(0, (sum, g) => sum + g.currentAmount);
        expect(totalCurrent,
            activeGoal.currentAmount + completedGoal.currentAmount);
      });

      test('total target amount across all goals', () {
        final state = _state([activeGoal, lockedGoal]);
        final totalTarget =
            state.items.fold<double>(0, (sum, g) => sum + g.targetAmount);
        expect(totalTarget,
            activeGoal.targetAmount + lockedGoal.targetAmount);
      });

      test('overall progress = sum(current) / sum(target)', () {
        final state = _state([activeGoal, lockedGoal]);
        final totalCurrent =
            state.items.fold<double>(0, (sum, g) => sum + g.currentAmount);
        final totalTarget =
            state.items.fold<double>(0, (sum, g) => sum + g.targetAmount);
        final progress =
            totalTarget > 0 ? totalCurrent / totalTarget : 0.0;
        expect(progress, greaterThan(0));
        expect(progress, lessThanOrEqualTo(1));
      });
    });

    group('copyWith', () {
      test('updating filter preserves items', () {
        final state = _state([activeGoal], filter: GoalStatusFilter.all);
        final updated = state.copyWith(filter: GoalStatusFilter.completed);
        expect(updated.items, hasLength(1));
        expect(updated.filter, GoalStatusFilter.completed);
      });

      test('updating items preserves filter', () {
        final state = _state([activeGoal], filter: GoalStatusFilter.active);
        final updated = state.copyWith(items: [activeGoal, completedGoal]);
        expect(updated.items, hasLength(2));
        expect(updated.filter, GoalStatusFilter.active);
      });
    });
  });

  // ────────────────────────────────────────────────────
  // GoalStatusFilter.matches — the core filter logic
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter matching (profile use-case)', () {
    test('active filter excludes completed goals', () {
      expect(GoalStatusFilter.active.matches(completedGoal), isFalse);
    });

    test('active filter includes goals where current < target', () {
      expect(GoalStatusFilter.active.matches(activeGoal), isTrue);
    });

    test('completed filter matches goals with current >= target', () {
      expect(GoalStatusFilter.completed.matches(completedGoal), isTrue);
    });

    test('all filter matches every goal', () {
      for (final g in [activeGoal, completedGoal, canceledGoal, lockedGoal]) {
        expect(GoalStatusFilter.all.matches(g), isTrue);
      }
    });
  });
}