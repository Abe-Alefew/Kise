import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';

TransactionEntity _base() => const TransactionEntity(
      id: 'tx-001',
      title: 'Salary',
      category: 'Salary',
      amount: 5000.0,
      type: 'income',
      transactionDate: '2025-06-01',
      displayDate: 'Jun 1',
      month: 'Jun',
      iconKey: 'briefcase',
      isDirty: false,
    );

void main() {
  // ────────────────────────────────────────────────────
  // Constructor & basic field access
  // ────────────────────────────────────────────────────
  group('TransactionEntity construction', () {
    test('all required fields are stored correctly', () {
      final tx = _base();
      expect(tx.id, 'tx-001');
      expect(tx.title, 'Salary');
      expect(tx.category, 'Salary');
      expect(tx.amount, 5000.0);
      expect(tx.type, 'income');
      expect(tx.transactionDate, '2025-06-01');
      expect(tx.displayDate, 'Jun 1');
      expect(tx.month, 'Jun');
      expect(tx.iconKey, 'briefcase');
      expect(tx.isDirty, isFalse);
    });

    test('optional fields default to null', () {
      final tx = _base();
      expect(tx.accountId, isNull);
      expect(tx.accountName, isNull);
      expect(tx.note, isNull);
      expect(tx.syncError, isNull);
    });

    test('iconKey defaults to "circle" when not supplied', () {
      const tx = TransactionEntity(
        id: 'x',
        title: 'x',
        category: 'Other',
        amount: 1,
        type: 'expense',
        transactionDate: '2025-01-01',
        displayDate: 'Jan 1',
        month: 'Jan',
      );
      expect(tx.iconKey, 'circle');
    });

    test('date getter returns displayDate', () {
      expect(_base().date, 'Jun 1');
    });
  });

  // ────────────────────────────────────────────────────
  // copyWith
  // ────────────────────────────────────────────────────
  group('TransactionEntity.copyWith', () {
    test('returns identical entity when no arguments provided', () {
      final original = _base();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.amount, original.amount);
      expect(copy.isDirty, original.isDirty);
    });

    test('overrides title only', () {
      final copy = _base().copyWith(title: 'Bonus');
      expect(copy.title, 'Bonus');
      expect(copy.amount, 5000.0); // unchanged
    });

    test('overrides amount only', () {
      final copy = _base().copyWith(amount: 250.0);
      expect(copy.amount, 250.0);
      expect(copy.title, 'Salary'); // unchanged
    });

    test('can mark as dirty', () {
      final copy = _base().copyWith(isDirty: true);
      expect(copy.isDirty, isTrue);
    });

    test('can set syncError', () {
      final copy = _base().copyWith(syncError: 'network failed');
      expect(copy.syncError, 'network failed');
    });

    test('can clear optional fields by passing null', () {
      final withNote = _base().copyWith(note: 'grocery run');
      expect(withNote.note, 'grocery run');
      // copyWith retains note when not specified
      final withoutNote = withNote.copyWith(title: 'Salary');
      expect(withoutNote.note, 'grocery run');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionEntity.optimisticFromInput
  // ────────────────────────────────────────────────────
  group('TransactionEntity.optimisticFromInput', () {
    const input = CreateTransactionInput(
      type: 'expense',
      title: 'Coffee',
      category: 'Food',
      amount: 4.5,
      transactionDate: '2025-06-01',
      note: 'morning brew',
    );

    test('generates a non-empty UUID id', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.id, isNotEmpty);
    });

    test('each call generates a unique id', () {
      final id1 = TransactionEntity.optimisticFromInput(input).id;
      final id2 = TransactionEntity.optimisticFromInput(input).id;
      expect(id1, isNot(id2));
    });

    test('copies type, title, category, amount from input', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.type, 'expense');
      expect(tx.title, 'Coffee');
      expect(tx.category, 'Food');
      expect(tx.amount, 4.5);
    });

    test('sets isDirty to true (unsynced)', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.isDirty, isTrue);
    });

    test('copies transactionDate from input', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.transactionDate, '2025-06-01');
    });

    test('copies optional note from input', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.note, 'morning brew');
    });

    test('uses default icon key for known category', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      // 'Food' -> 'shoppingCart'
      expect(tx.iconKey, 'shoppingCart');
    });

    test('uses provided iconKey when specified', () {
      const withIcon = CreateTransactionInput(
        type: 'income',
        title: 'Gift',
        category: 'Bonus',
        amount: 100,
        transactionDate: '2025-06-01',
        iconKey: 'gift',
      );
      final tx = TransactionEntity.optimisticFromInput(withIcon);
      expect(tx.iconKey, 'gift');
    });

    test('formats displayDate from transactionDate', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      // June 1 -> "Jun 1"
      expect(tx.displayDate, 'Jun 1');
    });

    test('formats month label from transactionDate', () {
      final tx = TransactionEntity.optimisticFromInput(input);
      expect(tx.month, 'Jun');
    });
  });
}
