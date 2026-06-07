import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';

import '../../../../helpers/test_data/goal_fixtures.dart';

void main() {
  // ────────────────────────────────────────────────────
  // apiValue
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter.apiValue', () {
    test('all → "all"', () => expect(GoalStatusFilter.all.apiValue, 'all'));
    test('active → "active"',
        () => expect(GoalStatusFilter.active.apiValue, 'active'));
    test('completed → "completed"',
        () => expect(GoalStatusFilter.completed.apiValue, 'completed'));
    test('canceled → "canceled"',
        () => expect(GoalStatusFilter.canceled.apiValue, 'canceled'));
  });

  // ────────────────────────────────────────────────────
  // uiLabel
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter.uiLabel', () {
    test('all → "All"', () => expect(GoalStatusFilter.all.uiLabel, 'All'));
    test('active → "Active"',
        () => expect(GoalStatusFilter.active.uiLabel, 'Active'));
    test('completed → "Completed"',
        () => expect(GoalStatusFilter.completed.uiLabel, 'Completed'));
    test('canceled → "Canceled"',
        () => expect(GoalStatusFilter.canceled.uiLabel, 'Canceled'));
  });

  // ────────────────────────────────────────────────────
  // toQueryParameters
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter.toQueryParameters', () {
    test('all produces empty map', () {
      expect(GoalStatusFilter.all.toQueryParameters(), isEmpty);
    });

    test('active produces {status: active}', () {
      expect(
        GoalStatusFilter.active.toQueryParameters(),
        {'status': 'active'},
      );
    });

    test('completed produces {status: completed}', () {
      expect(
        GoalStatusFilter.completed.toQueryParameters(),
        {'status': 'completed'},
      );
    });

    test('canceled produces {status: canceled}', () {
      expect(
        GoalStatusFilter.canceled.toQueryParameters(),
        {'status': 'canceled'},
      );
    });
  });

  // ────────────────────────────────────────────────────
  // fromApiValue
  // ────────────────────────────────────────────────────
  group('GoalStatusFilterX.fromApiValue', () {
    test('"all" → all', () {
      expect(GoalStatusFilterX.fromApiValue('all'), GoalStatusFilter.all);
    });
    test('"active" → active', () {
      expect(GoalStatusFilterX.fromApiValue('active'), GoalStatusFilter.active);
    });
    test('"completed" → completed', () {
      expect(GoalStatusFilterX.fromApiValue('completed'),
          GoalStatusFilter.completed);
    });
    test('"canceled" → canceled', () {
      expect(
          GoalStatusFilterX.fromApiValue('canceled'), GoalStatusFilter.canceled);
    });
    test('unknown defaults to all', () {
      expect(GoalStatusFilterX.fromApiValue('unknown'), GoalStatusFilter.all);
    });
    test('case-insensitive: "ACTIVE" → active', () {
      expect(GoalStatusFilterX.fromApiValue('ACTIVE'), GoalStatusFilter.active);
    });
    test('empty string defaults to all', () {
      expect(GoalStatusFilterX.fromApiValue(''), GoalStatusFilter.all);
    });
  });

  // ────────────────────────────────────────────────────
  // fromUiLabel
  // ────────────────────────────────────────────────────
  group('GoalStatusFilterX.fromUiLabel', () {
    test('"All" → all', () {
      expect(GoalStatusFilterX.fromUiLabel('All'), GoalStatusFilter.all);
    });
    test('"Active" → active', () {
      expect(GoalStatusFilterX.fromUiLabel('Active'), GoalStatusFilter.active);
    });
    test('"Completed" → completed', () {
      expect(GoalStatusFilterX.fromUiLabel('Completed'),
          GoalStatusFilter.completed);
    });
    test('"Canceled" → canceled', () {
      expect(
          GoalStatusFilterX.fromUiLabel('Canceled'), GoalStatusFilter.canceled);
    });
    test('unknown defaults to all', () {
      expect(GoalStatusFilterX.fromUiLabel('Pending'), GoalStatusFilter.all);
    });
    test('trims whitespace', () {
      expect(GoalStatusFilterX.fromUiLabel(' Active '), GoalStatusFilter.active);
    });
  });

  // ────────────────────────────────────────────────────
  // Round-trips
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter round-trips', () {
    for (final filter in GoalStatusFilter.values) {
      test('${filter.name} round-trips via apiValue', () {
        expect(GoalStatusFilterX.fromApiValue(filter.apiValue), filter);
      });
      test('${filter.name} round-trips via uiLabel', () {
        expect(GoalStatusFilterX.fromUiLabel(filter.uiLabel), filter);
      });
    }
  });

  // ────────────────────────────────────────────────────
  // matches() — filters GoalEntity list
  // ────────────────────────────────────────────────────
  group('GoalStatusFilter.matches', () {
    test('all matches every goal', () {
      expect(GoalStatusFilter.all.matches(activeGoal), isTrue);
      expect(GoalStatusFilter.all.matches(completedGoal), isTrue);
      expect(GoalStatusFilter.all.matches(canceledGoal), isTrue);
    });

    test('active matches active goal with current < target', () {
      expect(GoalStatusFilter.active.matches(activeGoal), isTrue);
    });

    test('active does NOT match completed goal', () {
      // completedGoal has status='completed'
      expect(GoalStatusFilter.active.matches(completedGoal), isFalse);
    });

    test('active does NOT match canceled goal', () {
      expect(GoalStatusFilter.active.matches(canceledGoal), isFalse);
    });

    test('completed matches when status == "completed"', () {
      expect(GoalStatusFilter.completed.matches(completedGoal), isTrue);
    });

    test('completed matches when current >= target regardless of status', () {
      // activeGoal with 400/1000 → not matched
      expect(GoalStatusFilter.completed.matches(activeGoal), isFalse);

      // A goal where current == target → matched even with status 'active'
      final fullGoal = makeGoal(
        currentAmount: 1000,
        targetAmount: 1000,
        status: 'active',
        isCompleted: false,
      );
      expect(GoalStatusFilter.completed.matches(fullGoal), isTrue);
    });

    test('canceled matches canceled goal', () {
      expect(GoalStatusFilter.canceled.matches(canceledGoal), isTrue);
    });

    test('canceled does NOT match active goal', () {
      expect(GoalStatusFilter.canceled.matches(activeGoal), isFalse);
    });
  });
}
