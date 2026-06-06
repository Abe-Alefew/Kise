import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

void main() {
  
  
  
  group('DebtDateParser.toIsoDate', () {
    test('pads single-digit month and day with zeros', () {
      expect(DebtDateParser.toIsoDate(DateTime(2025, 3, 5)), '2025-03-05');
    });

    test('handles double-digit month and day', () {
      expect(DebtDateParser.toIsoDate(DateTime(2025, 11, 20)), '2025-11-20');
    });

    test('handles end of year', () {
      expect(DebtDateParser.toIsoDate(DateTime(2024, 12, 31)), '2024-12-31');
    });
  });

  
  
  
  group('DebtDateParser.parseIsoDate', () {
    test('parses valid ISO date string', () {
      final result = DebtDateParser.parseIsoDate('2025-06-15');
      expect(result, isNotNull);
      expect(result!.month, 6);
      expect(result.day, 15);
      expect(result.year, 2025);
    });

    test('returns null for empty string', () {
      expect(DebtDateParser.parseIsoDate(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(DebtDateParser.parseIsoDate('   '), isNull);
    });

    test('returns null for unparseable string', () {
      expect(DebtDateParser.parseIsoDate('not-a-date'), isNull);
    });

    test('parses full ISO8601 datetime string', () {
      final result =
          DebtDateParser.parseIsoDate('2025-06-15T12:00:00.000Z');
      expect(result, isNotNull);
      expect(result!.year, 2025);
    });
  });

  
  
  
  group('CreateDebtInput.toJson', () {
    test('includes all required fields', () {
      const input = CreateDebtInput(
        personName: 'Alice',
        type: DebtType.lent,
        totalAmount: 500,
        debtDate: '2025-06-01',
      );
      final json = input.toJson();
      expect(json['personName'], 'Alice');
      expect(json['type'], 'lent');
      expect(json['totalAmount'], 500.0);
      expect(json['debtDate'], '2025-06-01');
    });

    test('trims whitespace from personName', () {
      const input = CreateDebtInput(
        personName: '  Bob  ',
        type: DebtType.borrowed,
        totalAmount: 200,
        debtDate: '2025-06-01',
      );
      expect(input.toJson()['personName'], 'Bob');
    });

    test('serializes borrowed type correctly', () {
      const input = CreateDebtInput(
        personName: 'Charlie',
        type: DebtType.borrowed,
        totalAmount: 300,
        debtDate: '2025-06-01',
      );
      expect(input.toJson()['type'], 'borrowed');
    });

    test('omits null notes', () {
      const input = CreateDebtInput(
        personName: 'Dave',
        type: DebtType.lent,
        totalAmount: 100,
        debtDate: '2025-06-01',
      );
      expect(input.toJson().containsKey('notes'), isFalse);
    });

    test('omits empty/whitespace notes', () {
      const input = CreateDebtInput(
        personName: 'Eve',
        type: DebtType.lent,
        totalAmount: 100,
        debtDate: '2025-06-01',
        notes: '   ',
      );
      expect(input.toJson().containsKey('notes'), isFalse);
    });

    test('includes non-empty notes', () {
      const input = CreateDebtInput(
        personName: 'Frank',
        type: DebtType.lent,
        totalAmount: 100,
        debtDate: '2025-06-01',
        notes: 'coffee money',
      );
      expect(input.toJson()['notes'], 'coffee money');
    });
  });

  
  
  
  group('RecordPaymentInput.toJson', () {
    test('includes amount and paymentDate', () {
      const input = RecordPaymentInput(
        amount: 150,
        paymentDate: '2025-07-01',
      );
      final json = input.toJson();
      expect(json['amount'], 150.0);
      expect(json['paymentDate'], '2025-07-01');
    });

    test('omits null notes', () {
      const input = RecordPaymentInput(amount: 50, paymentDate: '2025-07-01');
      expect(input.toJson().containsKey('notes'), isFalse);
    });

    test('includes notes when provided', () {
      const input = RecordPaymentInput(
        amount: 50,
        paymentDate: '2025-07-01',
        notes: 'partial repayment',
      );
      expect(input.toJson()['notes'], 'partial repayment');
    });

    test('omits whitespace-only notes', () {
      const input = RecordPaymentInput(
        amount: 50,
        paymentDate: '2025-07-01',
        notes: '   ',
      );
      expect(input.toJson().containsKey('notes'), isFalse);
    });
  });

  
  
  
  group('UpdateDebtInput.isEmpty', () {
    test('is true when no fields set', () {
      const input = UpdateDebtInput();
      expect(input.isEmpty, isTrue);
    });

    test('is false when personName is set', () {
      const input = UpdateDebtInput(personName: 'Grace');
      expect(input.isEmpty, isFalse);
    });

    test('is false when only totalAmount is set', () {
      const input = UpdateDebtInput(totalAmount: 999);
      expect(input.isEmpty, isFalse);
    });
  });

  group('UpdateDebtInput.toJson', () {
    test('includes only set fields', () {
      const input = UpdateDebtInput(personName: 'Henry', totalAmount: 600);
      final json = input.toJson();
      expect(json['personName'], 'Henry');
      expect(json['totalAmount'], 600.0);
      expect(json.containsKey('type'), isFalse);
      expect(json.containsKey('debtDate'), isFalse);
    });

    test('serializes lent type', () {
      const input = UpdateDebtInput(type: DebtType.lent);
      expect(input.toJson()['type'], 'lent');
    });

    test('serializes borrowed type', () {
      const input = UpdateDebtInput(type: DebtType.borrowed);
      expect(input.toJson()['type'], 'borrowed');
    });

    test('empty input produces empty json', () {
      const input = UpdateDebtInput();
      expect(input.toJson(), isEmpty);
    });
  });
}
