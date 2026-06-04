import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

void main() {
  // ────────────────────────────────────────────────────
  // GoalDateParser.toIsoDate
  // ────────────────────────────────────────────────────
  group('GoalDateParser.toIsoDate', () {
    test('formats single-digit day and month with leading zeros', () {
      final date = DateTime(2025, 1, 5);
      expect(GoalDateParser.toIsoDate(date), '2025-01-05');
    });

    test('formats double-digit day and month correctly', () {
      final date = DateTime(2025, 11, 30);
      expect(GoalDateParser.toIsoDate(date), '2025-11-30');
    });

    test('formats end-of-year date', () {
      final date = DateTime(2024, 12, 31);
      expect(GoalDateParser.toIsoDate(date), '2024-12-31');
    });

    test('formats year 2000 with full 4 digits', () {
      final date = DateTime(2000, 1, 1);
      expect(GoalDateParser.toIsoDate(date), '2000-01-01');
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDateParser.parseDueDate
  // ────────────────────────────────────────────────────
  group('GoalDateParser.parseDueDate', () {
    test('returns null for empty string', () {
      expect(GoalDateParser.parseDueDate(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(GoalDateParser.parseDueDate('   '), isNull);
    });

    test('parses ISO date string "2025-06-15"', () {
      final result = GoalDateParser.parseDueDate('2025-06-15');
      expect(result, isNotNull);
      expect(result!.month, 6);
      expect(result.day, 15);
      expect(result.year, 2025);
    });

    test('parses display format "Due Mon Jan 15 2025"', () {
      final result = GoalDateParser.parseDueDate('Due Mon Jan 15 2025');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('parses display format without "Due " prefix', () {
      final result = GoalDateParser.parseDueDate('Mon Jan 15 2025');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('returns null for malformed string', () {
      expect(GoalDateParser.parseDueDate('not-a-date'), isNull);
    });

    test('returns null for partial display format', () {
      expect(GoalDateParser.parseDueDate('Due Mon Jan'), isNull);
    });

    test('parses December correctly (month index 11)', () {
      final result = GoalDateParser.parseDueDate('Due Fri Dec 31 2027');
      expect(result, isNotNull);
      expect(result!.month, 12);
    });

    test('parses display format "Due Tue Feb 10 2026"', () {
      final result = GoalDateParser.parseDueDate('Due Tue Feb 10 2026');
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 2);
      expect(result.day, 10);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDateParser.formatDueDateDisplay
  // ────────────────────────────────────────────────────
  group('GoalDateParser.formatDueDateDisplay', () {
    test('formats a Monday correctly', () {
      // 2025-01-06 is a Monday
      final date = DateTime(2025, 1, 6);
      expect(GoalDateParser.formatDueDateDisplay(date), 'Due Mon Jan 6 2025');
    });

    test('formats a Friday in December correctly', () {
      // 2024-12-27 is a Friday
      final date = DateTime(2024, 12, 27);
      expect(GoalDateParser.formatDueDateDisplay(date), 'Due Fri Dec 27 2024');
    });

    test('output starts with "Due "', () {
      final date = DateTime(2025, 6, 15);
      expect(GoalDateParser.formatDueDateDisplay(date), startsWith('Due '));
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDateParser.normalizePeriod
  // ────────────────────────────────────────────────────
  group('GoalDateParser.normalizePeriod', () {
    test('returns "daily" unchanged', () {
      expect(GoalDateParser.normalizePeriod('daily'), 'daily');
    });

    test('returns "weekly" unchanged', () {
      expect(GoalDateParser.normalizePeriod('weekly'), 'weekly');
    });

    test('returns "monthly" unchanged', () {
      expect(GoalDateParser.normalizePeriod('monthly'), 'monthly');
    });

    test('returns "yearly" unchanged', () {
      expect(GoalDateParser.normalizePeriod('yearly'), 'yearly');
    });

    test('returns "one-time" unchanged', () {
      expect(GoalDateParser.normalizePeriod('one-time'), 'one-time');
    });

    test('converts "one time" (with space) to "one-time"', () {
      expect(GoalDateParser.normalizePeriod('one time'), 'one-time');
    });

    test('lowercases "Monthly" to "monthly"', () {
      expect(GoalDateParser.normalizePeriod('Monthly'), 'monthly');
    });

    test('returns "monthly" for empty string', () {
      expect(GoalDateParser.normalizePeriod(''), 'monthly');
    });

    test('trims whitespace before normalizing', () {
      expect(GoalDateParser.normalizePeriod('  daily  '), 'daily');
    });

    test('passes through unknown periods in lowercase', () {
      expect(GoalDateParser.normalizePeriod('biweekly'), 'biweekly');
    });
  });
}
