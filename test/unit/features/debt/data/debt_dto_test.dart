import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/data/dtos/debt_dto.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

Map<String, dynamic> _validJson({
  String type = 'lent',
  double total = 1000,
  double paid = 0,
  String status = 'pending',
}) => {
  'id': 'debt-dto-001',
  'personName': 'Alice',
  'type': type,
  'totalAmount': total,
  'paidAmount': paid,
  'status': status,
  'debtDate': '2025-06-01',
  'payments': [],
};

void main() {
  
  
  
  group('DebtDto.fromJson', () {
    test('parses all required fields', () {
      final dto = DebtDto.fromJson(_validJson());
      expect(dto.id, 'debt-dto-001');
      expect(dto.personName, 'Alice');
      expect(dto.type, 'lent');
      expect(dto.totalAmount, 1000.0);
      expect(dto.paidAmount, 0.0);
      expect(dto.status, 'pending');
      expect(dto.debtDate, '2025-06-01');
    });

    test('computes remaining = total - paid when not provided', () {
      final dto = DebtDto.fromJson(_validJson(total: 800, paid: 200));
      expect(dto.remaining, 600.0);
    });

    test('uses provided remaining when present', () {
      final json = _validJson()..['remaining'] = 750.0;
      final dto = DebtDto.fromJson(json);
      expect(dto.remaining, 750.0);
    });

    test('parses "borrowed" type string', () {
      final dto = DebtDto.fromJson(_validJson(type: 'borrowed'));
      expect(dto.type, 'borrowed');
    });

    test('handles string numeric amounts', () {
      final json = _validJson()
        ..['totalAmount'] = '500'
        ..['paidAmount'] = '100';
      final dto = DebtDto.fromJson(json);
      expect(dto.totalAmount, 500.0);
      expect(dto.paidAmount, 100.0);
    });

    test('parses payments list', () {
      final json = _validJson()
        ..['payments'] = [
          {'id': 'pay-1', 'amount': 200.0, 'paymentDate': '2025-07-01'},
        ];
      final dto = DebtDto.fromJson(json);
      expect(dto.payments, hasLength(1));
      expect(dto.payments.first.amount, 200.0);
    });

    test('empty payments list produces empty payments', () {
      final dto = DebtDto.fromJson(_validJson());
      expect(dto.payments, isEmpty);
    });

    test('optional fields default to null', () {
      final dto = DebtDto.fromJson(_validJson());
      expect(dto.notes, isNull);
      expect(dto.createdAt, isNull);
      expect(dto.updatedAt, isNull);
    });

    test('personInitial defaults to null when absent', () {
      final dto = DebtDto.fromJson(_validJson());
      expect(dto.personInitial, isNull);
    });
  });

  
  
  
  group('DebtDto.listFromEnvelope', () {
    test('parses flat list', () {
      final list = DebtDto.listFromEnvelope([_validJson(), _validJson()]);
      expect(list, hasLength(2));
    });

    test('parses {items:[...]} envelope', () {
      final list = DebtDto.listFromEnvelope({
        'items': [_validJson()],
      });
      expect(list, hasLength(1));
    });

    test('returns empty for null input', () {
      expect(DebtDto.listFromEnvelope(null), isEmpty);
    });

    test('returns empty for empty list', () {
      expect(DebtDto.listFromEnvelope([]), isEmpty);
    });
  });

  
  
  
  group('DebtDto.toEntity', () {
    test('maps lent type to DebtType.lent', () {
      final entity = DebtDto.fromJson(_validJson(type: 'lent')).toEntity();
      expect(entity.type, DebtType.lent);
    });

    test('maps borrowed type to DebtType.borrowed', () {
      final entity = DebtDto.fromJson(_validJson(type: 'borrowed')).toEntity();
      expect(entity.type, DebtType.borrowed);
    });

    test('isDirty=false by default', () {
      final entity = DebtDto.fromJson(_validJson()).toEntity();
      expect(entity.isDirty, isFalse);
    });

    test('propagates isDirty=true', () {
      final entity = DebtDto.fromJson(_validJson()).toEntity(isDirty: true);
      expect(entity.isDirty, isTrue);
    });

    test('maps pending status correctly', () {
      final entity = DebtDto.fromJson(_validJson(status: 'pending')).toEntity();
      expect(entity.status, DebtStatus.pending);
    });

    test('maps settled status correctly', () {
      final entity = DebtDto.fromJson(
        _validJson(status: 'settled', total: 500, paid: 500),
      ).toEntity();
      expect(entity.status, DebtStatus.settled);
    });

    test('derives personInitial from personName when not provided', () {
      final entity = DebtDto.fromJson(_validJson()).toEntity();
      expect(entity.personInitial, 'A'); 
    });

    test('preserves all amounts in entity', () {
      final entity = DebtDto.fromJson(
        _validJson(total: 1000, paid: 300),
      ).toEntity();
      expect(entity.totalAmount, 1000.0);
      expect(entity.paidAmount, 300.0);
      expect(entity.remaining, 700.0);
    });
  });

  
  
  
  group('DebtDto.applyUpdate', () {
    final base = DebtDto.fromJson(_validJson(total: 1000, paid: 0));
    final updatedAt = DateTime(2025, 7, 1);

    test('updates personName', () {
      final updated = base.applyUpdate(
        const UpdateDebtInput(personName: 'Bob'),
        updatedAt: updatedAt,
      );
      expect(updated.personName, 'Bob');
    });

    test('updates totalAmount and recomputes remaining', () {
      final updated = base.applyUpdate(
        const UpdateDebtInput(totalAmount: 500),
        updatedAt: updatedAt,
      );
      expect(updated.totalAmount, 500.0);
      expect(updated.remaining, 500.0); 
    });

    test('recomputes status as settled when newTotal <= paidAmount', () {
      final partialBase = DebtDto.fromJson(_validJson(total: 1000, paid: 500));
      final updated = partialBase.applyUpdate(
        const UpdateDebtInput(totalAmount: 500), 
        updatedAt: updatedAt,
      );
      expect(updated.status, 'settled');
    });

    test('preserves fields not in UpdateDebtInput', () {
      final updated = base.applyUpdate(
        const UpdateDebtInput(personName: 'Charlie'),
        updatedAt: updatedAt,
      );
      expect(updated.totalAmount, 1000.0); 
      expect(updated.type, 'lent'); 
    });
  });

  
  
  
  group('DebtDto.applyPayment', () {
    final base = DebtDto.fromJson(_validJson(total: 1000, paid: 0));
    final payment = DebtPaymentDto.fromJson({
      'id': 'pay-new',
      'amount': 400.0,
      'paymentDate': '2025-07-01',
    });
    final updatedAt = DateTime(2025, 7, 1);

    test('adds payment amount to paidAmount', () {
      final updated = base.applyPayment(payment: payment, updatedAt: updatedAt);
      expect(updated.paidAmount, 400.0);
    });

    test('reduces remaining by payment amount', () {
      final updated = base.applyPayment(payment: payment, updatedAt: updatedAt);
      expect(updated.remaining, 600.0);
    });

    test('status becomes partial after partial payment', () {
      final updated = base.applyPayment(payment: payment, updatedAt: updatedAt);
      expect(updated.status, 'partial');
    });

    test('status becomes settled when payment covers full amount', () {
      final fullPayment = DebtPaymentDto.fromJson({
        'id': 'pay-full',
        'amount': 1000.0,
        'paymentDate': '2025-07-01',
      });
      final updated = base.applyPayment(
        payment: fullPayment,
        updatedAt: updatedAt,
      );
      expect(updated.status, 'settled');
      expect(updated.remaining, 0.0);
    });

    test('appends payment to payments list', () {
      final updated = base.applyPayment(payment: payment, updatedAt: updatedAt);
      expect(updated.payments, hasLength(1));
      expect(updated.payments.first.id, 'pay-new');
    });
  });

  
  
  
  group('DebtPaymentDto.fromJson', () {
    test('parses id, amount, paymentDate', () {
      final dto = DebtPaymentDto.fromJson({
        'id': 'p-1',
        'amount': 250,
        'paymentDate': '2025-08-01',
      });
      expect(dto.id, 'p-1');
      expect(dto.amount, 250.0);
      expect(dto.paymentDate, '2025-08-01');
    });

    test('parses string amount', () {
      final dto = DebtPaymentDto.fromJson({
        'id': 'p-2',
        'amount': '150.5',
        'paymentDate': '2025-08-01',
      });
      expect(dto.amount, 150.5);
    });

    test('optional notes default to null', () {
      final dto = DebtPaymentDto.fromJson({
        'id': 'p-3',
        'amount': 100,
        'paymentDate': '2025-08-01',
      });
      expect(dto.notes, isNull);
    });
  });

  
  
  
  group('DebtDto.fromCacheRow', () {
    final row = {
      'id': 'debt-cache-001',
      'person_name': 'Dave',
      'person_initial': 'D',
      'type': 'borrowed',
      'total_amount': 500.0,
      'paid_amount': 100.0,
      'remaining': 400.0,
      'status': 'partial',
      'debt_date': '2025-05-01',
      'notes': null,
      'created_at': null,
      'updated_at': null,
    };

    test('maps snake_case columns to camelCase fields', () {
      final dto = DebtDto.fromCacheRow(row);
      expect(dto.id, 'debt-cache-001');
      expect(dto.personName, 'Dave');
      expect(dto.type, 'borrowed');
      expect(dto.totalAmount, 500.0);
      expect(dto.paidAmount, 100.0);
      expect(dto.remaining, 400.0);
      expect(dto.status, 'partial');
    });

    test('accepts payments list', () {
      final payment = DebtPaymentDto.fromJson({
        'id': 'p-1',
        'amount': 100,
        'paymentDate': '2025-05-15',
      });
      final dto = DebtDto.fromCacheRow(row, payments: [payment]);
      expect(dto.payments, hasLength(1));
    });
  });
}



































































































































































