import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

void main() {
  // ────────────────────────────────────────────────────
  // CreateGoalInput.toJson
  // ────────────────────────────────────────────────────
  group('CreateGoalInput.toJson', () {
    test('includes all required fields', () {
      const input = CreateGoalInput(
        title: 'Emergency Fund',
        period: 'monthly',
        targetAmount: 5000,
        dueDate: '2025-12-31',
      );
      final json = input.toJson();
      expect(json['title'], 'Emergency Fund');
      expect(json['period'], 'monthly');
      expect(json['targetAmount'], 5000.0);
      expect(json['dueDate'], '2025-12-31');
    });

    test('currentAmount defaults to 0 when not provided', () {
      const input = CreateGoalInput(
        title: 'Laptop',
        period: 'monthly',
        targetAmount: 1000,
        dueDate: '2025-12-31',
      );
      expect(input.toJson()['currentAmount'], 0.0);
    });

    test('includes currentAmount when provided', () {
      const input = CreateGoalInput(
        title: 'Laptop',
        period: 'monthly',
        targetAmount: 1000,
        currentAmount: 200,
        dueDate: '2025-12-31',
      );
      expect(input.toJson()['currentAmount'], 200.0);
    });

    test('normalizes "Monthly" period to "monthly"', () {
      const input = CreateGoalInput(
        title: 'Test',
        period: 'Monthly',
        targetAmount: 100,
        dueDate: '2025-12-31',
      );
      expect(input.toJson()['period'], 'monthly');
    });

    test('normalizes "one time" to "one-time"', () {
      const input = CreateGoalInput(
        title: 'Trip',
        period: 'one time',
        targetAmount: 500,
        dueDate: '2025-12-31',
      );
      expect(input.toJson()['period'], 'one-time');
    });

    test('omits null/empty note', () {
      const input = CreateGoalInput(
        title: 'Savings',
        period: 'monthly',
        targetAmount: 1000,
        dueDate: '2025-12-31',
      );
      expect(input.toJson().containsKey('note'), isFalse);
    });

    test('omits whitespace-only note', () {
      const input = CreateGoalInput(
        title: 'Savings',
        period: 'monthly',
        targetAmount: 1000,
        dueDate: '2025-12-31',
        note: '   ',
      );
      expect(input.toJson().containsKey('note'), isFalse);
    });

    test('includes non-empty note trimmed', () {
      const input = CreateGoalInput(
        title: 'Savings',
        period: 'monthly',
        targetAmount: 1000,
        dueDate: '2025-12-31',
        note: '  save for rainy day  ',
      );
      expect(input.toJson()['note'], 'save for rainy day');
    });

    test('isLocked=false omits isLocked field', () {
      const input = CreateGoalInput(
        title: 'Test',
        period: 'monthly',
        targetAmount: 100,
        dueDate: '2025-12-31',
        isLocked: false,
      );
      expect(input.toJson().containsKey('isLocked'), isFalse);
    });

    test('isLocked=true includes isLocked field', () {
      const input = CreateGoalInput(
        title: 'Test',
        period: 'monthly',
        targetAmount: 100,
        dueDate: '2025-12-31',
        isLocked: true,
      );
      expect(input.toJson()['isLocked'], isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // LogDepositInput.toJson
  // ────────────────────────────────────────────────────
  group('LogDepositInput.toJson', () {
    test('includes required amount and source', () {
      const input = LogDepositInput(amount: 100, source: 'cash');
      final json = input.toJson();
      expect(json['amount'], 100.0);
      expect(json['source'], 'cash');
    });

    test('omits null accountId', () {
      const input = LogDepositInput(amount: 100, source: 'cash');
      expect(input.toJson().containsKey('accountId'), isFalse);
    });

    test('includes accountId when provided', () {
      const input = LogDepositInput(
        amount: 100,
        source: 'bank',
        accountId: 'acc-123',
      );
      expect(input.toJson()['accountId'], 'acc-123');
    });

    test('omits null depositedAt', () {
      const input = LogDepositInput(amount: 100, source: 'cash');
      expect(input.toJson().containsKey('depositedAt'), isFalse);
    });

    test('includes depositedAt when provided', () {
      const input = LogDepositInput(
        amount: 100,
        source: 'cash',
        depositedAt: '2025-06-01',
      );
      expect(input.toJson()['depositedAt'], '2025-06-01');
    });

    test('omits empty accountId', () {
      const input = LogDepositInput(
        amount: 100,
        source: 'cash',
        accountId: '',
      );
      expect(input.toJson().containsKey('accountId'), isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // UpdateGoalInput.toJson / isEmpty
  // ────────────────────────────────────────────────────
  group('UpdateGoalInput.isEmpty', () {
    test('is true when no fields set', () {
      const input = UpdateGoalInput();
      expect(input.isEmpty, isTrue);
    });

    test('is false when title is set', () {
      const input = UpdateGoalInput(title: 'New Title');
      expect(input.isEmpty, isFalse);
    });

    test('is false when only targetAmount is set', () {
      const input = UpdateGoalInput(targetAmount: 2000);
      expect(input.isEmpty, isFalse);
    });

    test('is false when only isLocked is set', () {
      const input = UpdateGoalInput(isLocked: true);
      expect(input.isEmpty, isFalse);
    });
  });

  group('UpdateGoalInput.toJson', () {
    test('includes only set fields', () {
      const input = UpdateGoalInput(title: 'Updated Title', targetAmount: 1500);
      final json = input.toJson();
      expect(json['title'], 'Updated Title');
      expect(json['targetAmount'], 1500.0);
      expect(json.containsKey('period'), isFalse);
      expect(json.containsKey('dueDate'), isFalse);
    });

    test('normalizes period in toJson', () {
      const input = UpdateGoalInput(period: 'Yearly');
      expect(input.toJson()['period'], 'yearly');
    });

    test('empty update produces empty json', () {
      const input = UpdateGoalInput();
      expect(input.toJson(), isEmpty);
    });

    test('includes status when set', () {
      const input = UpdateGoalInput(status: 'completed');
      expect(input.toJson()['status'], 'completed');
    });

    test('includes isLocked when set to false', () {
      const input = UpdateGoalInput(isLocked: false);
      expect(input.toJson()['isLocked'], isFalse);
    });
  });
}