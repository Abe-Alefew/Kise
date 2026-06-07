import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

void main() {
  // ────────────────────────────────────────────────────
  // GoalFormValidator.validateCreate
  // ────────────────────────────────────────────────────
  group('GoalFormValidator.validateCreate', () {
    test('returns null when all fields are valid', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Buy a laptop',
        targetAmountText: '1000',
        currentAmountText: '200',
        deadlineText: '2025-12-31',
      );
      expect(result, isNull);
    });

    test('returns error when title is blank', () {
      final result = GoalFormValidator.validateCreate(
        title: '   ',
        targetAmountText: '1000',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Please enter a goal name.');
    });

    test('returns error when title is empty string', () {
      final result = GoalFormValidator.validateCreate(
        title: '',
        targetAmountText: '1000',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Please enter a goal name.');
    });

    test('returns error when targetAmount is empty (required)', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Target amount is required.');
    });

    test('returns error when targetAmount is not a number', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: 'abc',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Target amount must be a valid number.');
    });

    test('returns error when targetAmount is zero', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '0',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Target amount must be greater than 0.');
    });

    test('returns error when targetAmount is negative', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '-100',
        currentAmountText: '0',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Target amount must be greater than 0.');
    });

    test('currentAmount is optional — empty is valid', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '',
        deadlineText: '2025-12-31',
      );
      expect(result, isNull);
    });

    test('returns error when currentAmount is provided but non-numeric', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: 'bad',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Saved so far must be a valid number.');
    });

    test('returns error when currentAmount is negative', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '-50',
        deadlineText: '2025-12-31',
      );
      expect(result, 'Saved so far cannot be negative.');
    });

    test('returns error when deadline is blank', () {
      // Use empty currentAmount (optional field) so deadline check is reached.
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '',
        deadlineText: '   ',
      );
      expect(result, 'Please select a due date.');
    });

    test('returns error when deadline cannot be parsed', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '',
        deadlineText: 'not-a-date',
      );
      expect(result, 'Due date format is invalid. Pick a date from the calendar.');
    });

    test('accepts ISO date format for deadline', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '',
        deadlineText: '2025-06-15',
      );
      expect(result, isNull);
    });

    test('accepts "Due Mon Jan 15 2025" display format for deadline', () {
      final result = GoalFormValidator.validateCreate(
        title: 'Laptop',
        targetAmountText: '500',
        currentAmountText: '',
        deadlineText: 'Due Mon Jan 15 2025',
      );
      expect(result, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalFormValidator.validateDeposit
  // ────────────────────────────────────────────────────
  group('GoalFormValidator.validateDeposit', () {
    test('returns null for valid deposit on unlocked goal', () {
      final result = GoalFormValidator.validateDeposit(
        amountText: '100',
        isLocked: false,
      );
      expect(result, isNull);
    });

    test('returns lock error when goal is locked', () {
      final result = GoalFormValidator.validateDeposit(
        amountText: '100',
        isLocked: true,
      );
      expect(result,
          'This goal is locked. Unlock it before adding a deposit.');
    });

    test('returns error when deposit amount is empty', () {
      final result = GoalFormValidator.validateDeposit(
        amountText: '',
        isLocked: false,
      );
      expect(result, 'Deposit amount is required.');
    });

    test('returns error when deposit amount is not a number', () {
      final result = GoalFormValidator.validateDeposit(
        amountText: 'xyz',
        isLocked: false,
      );
      expect(result, 'Deposit amount must be a valid number.');
    });

    test('returns error when deposit amount is zero', () {
      final result = GoalFormValidator.validateDeposit(
        amountText: '0',
        isLocked: false,
      );
      expect(result, 'Deposit amount must be greater than 0.');
    });

    test('lock check takes priority over amount validation', () {
      // Even with invalid amount, lock error is returned first
      final result = GoalFormValidator.validateDeposit(
        amountText: '',
        isLocked: true,
      );
      expect(result,
          'This goal is locked. Unlock it before adding a deposit.');
    });
  });

  // ────────────────────────────────────────────────────
  // GoalFormValidator.validateEdit
  // ────────────────────────────────────────────────────
  group('GoalFormValidator.validateEdit', () {
    test('returns null for valid edit on unlocked goal', () {
      final result = GoalFormValidator.validateEdit(
        title: 'New Title',
        targetAmountText: '2000',
        deadlineText: '2025-12-31',
        isLocked: false,
      );
      expect(result, isNull);
    });

    test('returns lock error when goal is locked', () {
      final result = GoalFormValidator.validateEdit(
        title: 'New Title',
        targetAmountText: '2000',
        deadlineText: '2025-12-31',
        isLocked: true,
      );
      expect(result, 'This goal is locked and cannot be edited.');
    });

    test('returns error when title is blank on unlocked goal', () {
      final result = GoalFormValidator.validateEdit(
        title: '',
        targetAmountText: '2000',
        deadlineText: '2025-12-31',
        isLocked: false,
      );
      expect(result, 'Please enter a goal name.');
    });

    test('returns error when targetAmount is zero on unlocked goal', () {
      final result = GoalFormValidator.validateEdit(
        title: 'Title',
        targetAmountText: '0',
        deadlineText: '2025-12-31',
        isLocked: false,
      );
      expect(result, 'Target amount must be greater than 0.');
    });

    test('returns error when deadline is blank on unlocked goal', () {
      final result = GoalFormValidator.validateEdit(
        title: 'Title',
        targetAmountText: '500',
        deadlineText: '',
        isLocked: false,
      );
      expect(result, 'Please select a due date.');
    });
  });
}
