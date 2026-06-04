import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';

void main() {
  // ────────────────────────────────────────────────────
  // CreateTransactionInput.toJson
  // ────────────────────────────────────────────────────
  group('CreateTransactionInput.toJson', () {
    test('includes all required fields', () {
      const input = CreateTransactionInput(
        type: 'expense',
        title: 'Coffee',
        category: 'Food',
        amount: 4.5,
        transactionDate: '2025-06-01',
      );
      final json = input.toJson();
      expect(json['type'], 'expense');
      expect(json['title'], 'Coffee');
      expect(json['category'], 'Food');
      expect(json['amount'], 4.5);
      expect(json['transactionDate'], '2025-06-01');
    });

    test('omits null accountId', () {
      const input = CreateTransactionInput(
        type: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 5000,
        transactionDate: '2025-06-01',
      );
      expect(input.toJson().containsKey('accountId'), isFalse);
    });

    test('includes accountId when provided', () {
      const input = CreateTransactionInput(
        type: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 5000,
        transactionDate: '2025-06-01',
        accountId: 'acc-123',
      );
      expect(input.toJson()['accountId'], 'acc-123');
    });

    test('omits null note', () {
      const input = CreateTransactionInput(
        type: 'expense',
        title: 'Food',
        category: 'Food',
        amount: 10,
        transactionDate: '2025-06-01',
      );
      expect(input.toJson().containsKey('note'), isFalse);
    });

    test('includes note when provided', () {
      const input = CreateTransactionInput(
        type: 'expense',
        title: 'Food',
        category: 'Food',
        amount: 10,
        transactionDate: '2025-06-01',
        note: 'lunch',
      );
      expect(input.toJson()['note'], 'lunch');
    });

    test('omits null iconKey', () {
      const input = CreateTransactionInput(
        type: 'expense',
        title: 'Food',
        category: 'Food',
        amount: 10,
        transactionDate: '2025-06-01',
      );
      expect(input.toJson().containsKey('iconKey'), isFalse);
    });

    test('includes iconKey when provided', () {
      const input = CreateTransactionInput(
        type: 'expense',
        title: 'Food',
        category: 'Food',
        amount: 10,
        transactionDate: '2025-06-01',
        iconKey: 'shoppingCart',
      );
      expect(input.toJson()['iconKey'], 'shoppingCart');
    });
  });

  // ────────────────────────────────────────────────────
  // UpdateTransactionInput.fromCreate
  // ────────────────────────────────────────────────────
  group('UpdateTransactionInput.fromCreate', () {
    const create = CreateTransactionInput(
      type: 'income',
      title: 'Bonus',
      category: 'Bonus',
      amount: 1000,
      transactionDate: '2025-07-01',
      accountId: 'acc-456',
      note: 'annual bonus',
      iconKey: 'gift',
    );

    test('copies all fields from CreateTransactionInput', () {
      final update = UpdateTransactionInput.fromCreate(create);
      expect(update.type, create.type);
      expect(update.title, create.title);
      expect(update.category, create.category);
      expect(update.amount, create.amount);
      expect(update.transactionDate, create.transactionDate);
      expect(update.accountId, create.accountId);
      expect(update.note, create.note);
      expect(update.iconKey, create.iconKey);
    });

    test('toJson produces same output as create.toJson', () {
      final update = UpdateTransactionInput.fromCreate(create);
      expect(update.toJson(), create.toJson());
    });
  });

  // ────────────────────────────────────────────────────
  // UpdateTransactionInput.toJson
  // ────────────────────────────────────────────────────
  group('UpdateTransactionInput.toJson', () {
    test('excludes null optional fields', () {
      const update = UpdateTransactionInput(
        type: 'expense',
        title: 'Bus',
        category: 'Transport',
        amount: 2.0,
        transactionDate: '2025-06-10',
      );
      final json = update.toJson();
      expect(json.containsKey('accountId'), isFalse);
      expect(json.containsKey('note'), isFalse);
      expect(json.containsKey('iconKey'), isFalse);
    });
  });
}
