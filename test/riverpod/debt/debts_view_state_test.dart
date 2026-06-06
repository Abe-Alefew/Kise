import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/data/dtos/debt_dto.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';
import 'package:kise/features/debt/presentation/state/debts_notifier.dart';



DebtEntity _debt({
  String id = 'debt-1',
  String name = 'Alice',
  DebtType type = DebtType.lent,
  double total = 1000,
  double paid = 0,
  DebtStatus? status,
}) =>
    DebtEntity(
      id: id,
      personName: name,
      type: type,
      totalAmount: total,
      paidAmount: paid,
      date: DateTime(2025, 1, 1),
      status: status,
    );

DebtsViewState _state(
  List<DebtEntity> items, {
  DebtSummary? summary,
  DebtListFilter filter = DebtListFilter.all,
}) =>
    DebtsViewState(
      items: items,
      summary: summary,
      fromCache: false,
      isStale: false,
      filter: filter,
    );

DebtSummary _summary({
  double owedToMe = 0,
  double iOwe = 0,
  double netPosition = 0,
  double recoveryRate = 0,
}) =>
    DebtSummary(
      owedToMe: owedToMe,
      iOwe: iOwe,
      netPosition: netPosition,
      recoveryRate: recoveryRate,
      counts: const {},
      totalLent: 0,
      totalBorrowed: 0,
      outstandingOwedToMe: owedToMe,
      outstandingIOwe: iOwe,
    );



void main() {
  
  
  
  group('DebtsViewState.owedToMe', () {
    test('returns summary.owedToMe when summary is present', () {
      final state = _state([], summary: _summary(owedToMe: 750));
      expect(state.owedToMe, 750.0);
    });

    test('computes owedToMe from lent non-settled items when no summary', () {
      final items = [
        _debt(type: DebtType.lent, total: 500, paid: 0),    
        _debt(id: 'd2', type: DebtType.lent, total: 200, paid: 50), 
      ];
      final state = _state(items);
      expect(state.owedToMe, 650.0);
    });

    test('excludes settled lent debts from owedToMe computation', () {
      final items = [
        _debt(type: DebtType.lent, total: 500, paid: 0),
        _debt(
          id: 'd2',
          type: DebtType.lent,
          total: 300,
          paid: 300,
          status: DebtStatus.settled,
        ),
      ];
      expect(_state(items).owedToMe, 500.0);
    });

    test('returns 0 when all lent debts are settled', () {
      final items = [
        _debt(
          type: DebtType.lent,
          total: 400,
          paid: 400,
          status: DebtStatus.settled,
        ),
      ];
      expect(_state(items).owedToMe, 0.0);
    });
  });

  
  
  
  group('DebtsViewState.iOwe', () {
    test('returns summary.iOwe when summary present', () {
      final state = _state([], summary: _summary(iOwe: 350));
      expect(state.iOwe, 350.0);
    });

    test('computes iOwe from borrowed non-settled debts', () {
      final items = [
        _debt(id: 'b1', type: DebtType.borrowed, total: 200, paid: 50),
        _debt(id: 'b2', type: DebtType.borrowed, total: 100, paid: 0),
      ];
      expect(_state(items).iOwe, 250.0); 
    });

    test('excludes settled borrowed debts', () {
      final items = [
        _debt(id: 'b1', type: DebtType.borrowed, total: 200, paid: 0),
        _debt(
          id: 'b2',
          type: DebtType.borrowed,
          total: 300,
          paid: 300,
          status: DebtStatus.settled,
        ),
      ];
      expect(_state(items).iOwe, 200.0);
    });
  });

  
  
  
  group('DebtsViewState.netPosition', () {
    test('returns summary.netPosition when summary present', () {
      final state = _state([], summary: _summary(netPosition: 400));
      expect(state.netPosition, 400.0);
    });

    test('computes owedToMe - iOwe when no summary', () {
      final items = [
        _debt(type: DebtType.lent, total: 1000, paid: 0),
        _debt(id: 'b', type: DebtType.borrowed, total: 400, paid: 0),
      ];
      expect(_state(items).netPosition, 600.0); 
    });

    test('netPosition is negative when iOwe > owedToMe', () {
      final items = [
        _debt(type: DebtType.lent, total: 100, paid: 0),
        _debt(id: 'b', type: DebtType.borrowed, total: 500, paid: 0),
      ];
      expect(_state(items).netPosition, -400.0);
    });
  });

  
  
  
  group('DebtsViewState.adjustedNetPosition', () {
    test('sums all lent totalAmount minus all borrowed totalAmount', () {
      final items = [
        _debt(type: DebtType.lent, total: 800, paid: 800, status: DebtStatus.settled),
        _debt(id: 'b', type: DebtType.borrowed, total: 300, paid: 0),
      ];
      expect(_state(items).adjustedNetPosition, 500.0); 
    });

    test('is 0 for empty list', () {
      expect(_state([]).adjustedNetPosition, 0.0);
    });

    test('is negative when borrowed exceeds lent', () {
      final items = [
        _debt(type: DebtType.lent, total: 200, paid: 0),
        _debt(id: 'b', type: DebtType.borrowed, total: 600, paid: 0),
      ];
      expect(_state(items).adjustedNetPosition, -400.0);
    });
  });

  
  
  
  group('DebtsViewState.recoveryRate', () {
    test('returns summary.recoveryRate when summary present', () {
      final state = _state([], summary: _summary(recoveryRate: 0.75));
      expect(state.recoveryRate, 0.75);
    });

    test('computes paid / total across all debts', () {
      final items = [
        _debt(type: DebtType.lent, total: 1000, paid: 500),
        _debt(id: 'd2', type: DebtType.borrowed, total: 500, paid: 250),
      ];
      
      expect(_state(items).recoveryRate, closeTo(0.5, 0.001));
    });

    test('returns 0 when total is 0', () {
      expect(_state([]).recoveryRate, 0.0);
    });

    test('returns 1.0 when everything is paid', () {
      final items = [
        _debt(type: DebtType.lent, total: 200, paid: 200),
        _debt(id: 'd2', type: DebtType.lent, total: 300, paid: 300),
      ];
      expect(_state(items).recoveryRate, closeTo(1.0, 0.001));
    });
  });

  
  
  
  group('DebtsViewState.copyWith', () {
    test('preserves all fields when no args passed', () {
      final original = _state([_debt()]);
      final copy = original.copyWith();
      expect(copy.items, original.items);
      expect(copy.fromCache, original.fromCache);
      expect(copy.filter, original.filter);
    });

    test('updates items only', () {
      final original = _state([]);
      final copy = original.copyWith(items: [_debt()]);
      expect(copy.items, hasLength(1));
      expect(copy.fromCache, original.fromCache);
    });

    test('updates filter only', () {
      final original = _state([], filter: DebtListFilter.all);
      final copy = original.copyWith(filter: DebtListFilter.lent);
      expect(copy.filter, DebtListFilter.lent);
    });

    test('can flip fromCache to true', () {
      final original = _state([]);
      final copy = original.copyWith(fromCache: true);
      expect(copy.fromCache, isTrue);
    });

    test('can update summary', () {
      final original = _state([]);
      final s = _summary(owedToMe: 999);
      final copy = original.copyWith(summary: s);
      expect(copy.owedToMe, 999.0);
    });
  });
}
















































































































































































































































































































































































































































































































































































































































































































































































