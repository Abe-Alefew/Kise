import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';

DebtEntity _makeDebt({
  double totalAmount = 1000.0,
  double paidAmount = 0.0,
  DebtType type = DebtType.lent,
  DebtStatus? status,
  String personName = 'Alice',
  List<PaymentRecord> payments = const [],
}) {
  return DebtEntity(
    id: 'debt-001',
    personName: personName,
    type: type,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    date: DateTime(2025, 1, 15),
    payments: payments,
    status: status,
  );
}

void main() {
  // ────────────────────────────────────────────────────
  // DebtEntity.deriveInitial
  // ────────────────────────────────────────────────────
  group('DebtEntity.deriveInitial', () {
    test('returns first uppercase letter of name', () {
      expect(DebtEntity.deriveInitial('Alice'), 'A');
    });

    test('uppercases a lowercase first letter', () {
      expect(DebtEntity.deriveInitial('bob'), 'B');
    });

    test('trims leading spaces before extraction', () {
      expect(DebtEntity.deriveInitial('  Carol'), 'C');
    });

    test('returns "?" for empty string', () {
      expect(DebtEntity.deriveInitial(''), '?');
    });

    test('returns "?" for whitespace-only string', () {
      expect(DebtEntity.deriveInitial('   '), '?');
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.deriveRemaining
  // ────────────────────────────────────────────────────
  group('DebtEntity.deriveRemaining', () {
    test('returns total - paid when positive', () {
      expect(DebtEntity.deriveRemaining(1000, 200), 800.0);
    });

    test('clamps to 0 when paidAmount exceeds totalAmount', () {
      expect(DebtEntity.deriveRemaining(500, 600), 0.0);
    });

    test('returns 0 when fully paid', () {
      expect(DebtEntity.deriveRemaining(1000, 1000), 0.0);
    });

    test('returns totalAmount when nothing paid', () {
      expect(DebtEntity.deriveRemaining(750, 0), 750.0);
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.deriveStatus
  // ────────────────────────────────────────────────────
  group('DebtEntity.deriveStatus', () {
    test('is pending when paidAmount is 0', () {
      expect(
        DebtEntity.deriveStatus(paidAmount: 0, totalAmount: 1000),
        DebtStatus.pending,
      );
    });

    test('is partial when paidAmount > 0 but < totalAmount', () {
      expect(
        DebtEntity.deriveStatus(paidAmount: 500, totalAmount: 1000),
        DebtStatus.partial,
      );
    });

    test('is settled when paidAmount >= totalAmount', () {
      expect(
        DebtEntity.deriveStatus(paidAmount: 1000, totalAmount: 1000),
        DebtStatus.settled,
      );
    });

    test('is settled when overpaid', () {
      expect(
        DebtEntity.deriveStatus(paidAmount: 1200, totalAmount: 1000),
        DebtStatus.settled,
      );
    });

    test('apiStatus "settled" overrides computed status', () {
      expect(
        DebtEntity.deriveStatus(
          paidAmount: 0,
          totalAmount: 1000,
          apiStatus: 'settled',
        ),
        DebtStatus.settled,
      );
    });

    test('apiStatus "partial" overrides computed pending', () {
      expect(
        DebtEntity.deriveStatus(
          paidAmount: 0,
          totalAmount: 1000,
          apiStatus: 'partial',
        ),
        DebtStatus.partial,
      );
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.statusFromApi / statusToApi
  // ────────────────────────────────────────────────────
  group('DebtEntity.statusFromApi', () {
    test('parses "settled"', () {
      expect(
        DebtEntity.statusFromApi('settled', paidAmount: 0, totalAmount: 100),
        DebtStatus.settled,
      );
    });

    test('parses "partial"', () {
      expect(
        DebtEntity.statusFromApi('partial', paidAmount: 50, totalAmount: 100),
        DebtStatus.partial,
      );
    });

    test('parses "pending"', () {
      expect(
        DebtEntity.statusFromApi('pending', paidAmount: 0, totalAmount: 100),
        DebtStatus.pending,
      );
    });

    test('null falls back to derived status', () {
      // paidAmount=0 → pending
      expect(
        DebtEntity.statusFromApi(null, paidAmount: 0, totalAmount: 100),
        DebtStatus.pending,
      );
    });

    test('unknown value falls back to derived status', () {
      expect(
        DebtEntity.statusFromApi('unknown', paidAmount: 50, totalAmount: 100),
        DebtStatus.partial,
      );
    });
  });

  group('DebtEntity.statusToApi', () {
    test('settled → "settled"', () {
      expect(DebtEntity.statusToApi(DebtStatus.settled), 'settled');
    });
    test('partial → "partial"', () {
      expect(DebtEntity.statusToApi(DebtStatus.partial), 'partial');
    });
    test('pending → "pending"', () {
      expect(DebtEntity.statusToApi(DebtStatus.pending), 'pending');
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity constructor — computed defaults
  // ────────────────────────────────────────────────────
  group('DebtEntity constructor', () {
    test('derives personInitial automatically', () {
      final debt = _makeDebt(personName: 'David');
      expect(debt.personInitial, 'D');
    });

    test('derives remaining from totalAmount and paidAmount', () {
      final debt = _makeDebt(totalAmount: 1000, paidAmount: 300);
      expect(debt.remaining, 700.0);
    });

    test('derives status as pending when nothing paid', () {
      final debt = _makeDebt(totalAmount: 1000, paidAmount: 0);
      expect(debt.status, DebtStatus.pending);
    });

    test('derives status as partial when partially paid', () {
      final debt = _makeDebt(totalAmount: 1000, paidAmount: 500);
      expect(debt.status, DebtStatus.partial);
    });

    test('derives status as settled when fully paid', () {
      final debt = _makeDebt(totalAmount: 1000, paidAmount: 1000);
      expect(debt.status, DebtStatus.settled);
    });

    test('accepts explicit personInitial override', () {
      final debt = DebtEntity(
        id: 'x',
        personName: 'Alice Smith',
        personInitial: 'AS',
        type: DebtType.lent,
        totalAmount: 100,
        date: DateTime(2025, 1, 1),
      );
      expect(debt.personInitial, 'AS');
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.copyWith
  // ────────────────────────────────────────────────────
  group('DebtEntity.copyWith', () {
    test('preserves all fields when no args', () {
      final debt = _makeDebt();
      final copy = debt.copyWith();
      expect(copy.id, debt.id);
      expect(copy.personName, debt.personName);
      expect(copy.totalAmount, debt.totalAmount);
    });

    test('updates paidAmount and recomputes remaining', () {
      final debt = _makeDebt(totalAmount: 1000, paidAmount: 0);
      final copy = debt.copyWith(paidAmount: 400);
      expect(copy.paidAmount, 400.0);
      expect(copy.remaining, 600.0);
    });

    test('clearSyncError sets syncError to null', () {
      final debt = _makeDebt().copyWith(syncError: 'network error');
      final cleared = debt.copyWith(clearSyncError: true);
      expect(cleared.syncError, isNull);
    });

    test('can switch type from lent to borrowed', () {
      final debt = _makeDebt(type: DebtType.lent);
      final copy = debt.copyWith(type: DebtType.borrowed);
      expect(copy.type, DebtType.borrowed);
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.fromJson
  // ────────────────────────────────────────────────────
  group('DebtEntity.fromJson', () {
    final json = {
      'id': 'debt-abc',
      'personName': 'Bob',
      'type': 'borrowed',
      'totalAmount': 500,
      'paidAmount': 100,
      'remaining': 400,
      'status': 'partial',
      'debtDate': '2025-03-01',
      'payments': [],
    };

    test('parses id, personName, type', () {
      final entity = DebtEntity.fromJson(json);
      expect(entity.id, 'debt-abc');
      expect(entity.personName, 'Bob');
      expect(entity.type, DebtType.borrowed);
    });

    test('parses amounts', () {
      final entity = DebtEntity.fromJson(json);
      expect(entity.totalAmount, 500.0);
      expect(entity.paidAmount, 100.0);
      expect(entity.remaining, 400.0);
    });

    test('parses status as partial', () {
      final entity = DebtEntity.fromJson(json);
      expect(entity.status, DebtStatus.partial);
    });

    test('parses debtDate', () {
      final entity = DebtEntity.fromJson(json);
      expect(entity.debtDate, '2025-03-01');
    });

    test('defaults isDirty to false', () {
      final entity = DebtEntity.fromJson(json);
      expect(entity.isDirty, isFalse);
    });

    test('handles numeric amounts as strings', () {
      final jsonStr = Map<String, dynamic>.from(json)
        ..['totalAmount'] = '750'
        ..['paidAmount'] = '250';
      final entity = DebtEntity.fromJson(jsonStr);
      expect(entity.totalAmount, 750.0);
      expect(entity.paidAmount, 250.0);
    });

    test('handles missing payments gracefully', () {
      final noPayments = Map<String, dynamic>.from(json)
        ..remove('payments');
      final entity = DebtEntity.fromJson(noPayments);
      expect(entity.payments, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // DebtEntity.toJson / round-trip
  // ────────────────────────────────────────────────────
  group('DebtEntity.toJson', () {
    test('includes required fields', () {
      final debt = _makeDebt(type: DebtType.borrowed);
      final json = debt.toJson();
      expect(json['id'], 'debt-001');
      expect(json['personName'], 'Alice');
      expect(json['type'], 'borrowed');
      expect(json['totalAmount'], 1000.0);
      expect(json['paidAmount'], 0.0);
    });

    test('round-trip preserves amounts', () {
      final debt = _makeDebt(totalAmount: 800, paidAmount: 200);
      final json = debt.toJson();
      final restored = DebtEntity.fromJson(json);
      expect(restored.totalAmount, 800.0);
      expect(restored.paidAmount, 200.0);
      expect(restored.remaining, 600.0);
    });
  });

  // ────────────────────────────────────────────────────
  // isPendingSyncDebtId
  // ────────────────────────────────────────────────────
  group('isPendingSyncDebtId', () {
    test('returns true for optimistic- prefix', () {
      expect(isPendingSyncDebtId('optimistic-1234'), isTrue);
    });

    test('returns false for real server id', () {
      expect(isPendingSyncDebtId('abc-123-real'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isPendingSyncDebtId(''), isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // PaymentRecord
  // ────────────────────────────────────────────────────
  group('PaymentRecord', () {
    test('fromJson parses amount as double', () {
      final json = {
        'id': 'pay-1',
        'amount': 150,
        'paymentDate': '2025-04-01',
      };
      final record = PaymentRecord.fromJson(json);
      expect(record.id, 'pay-1');
      expect(record.amount, 150.0);
    });

    test('fromJson handles string amount', () {
      final json = {
        'id': 'pay-2',
        'amount': '200.5',
        'paymentDate': '2025-04-15',
      };
      final record = PaymentRecord.fromJson(json);
      expect(record.amount, 200.5);
    });

    test('toJson round-trips id and amount', () {
      final json = {
        'id': 'pay-3',
        'amount': 300.0,
        'paymentDate': '2025-05-01',
      };
      final record = PaymentRecord.fromJson(json);
      final output = record.toJson();
      expect(output['id'], 'pay-3');
      expect(output['amount'], 300.0);
    });

    test('clearSyncError in copyWith sets syncError to null', () {
      final record = PaymentRecord(
        id: 'p1',
        amount: 50,
        date: DateTime(2025, 1, 1),
        syncError: 'server error',
      );
      final cleared = record.copyWith(clearSyncError: true);
      expect(cleared.syncError, isNull);
    });
  });
}
