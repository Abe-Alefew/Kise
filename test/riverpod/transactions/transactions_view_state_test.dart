import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/presentation/state/transactions_notifier.dart';

TransactionEntity _tx({
  String id = 'tx-1',
  String type = 'expense',
  String category = 'Food',
  double amount = 50,
}) =>
    TransactionEntity(
      id: id,
      title: 'Test $id',
      category: category,
      amount: amount,
      type: type,
      transactionDate: '2025-06-01',
      displayDate: 'Jun 1',
      month: 'Jun',
      iconKey: 'circle',
    );

TransactionsViewState _state({
  List<TransactionEntity> items = const [],
  bool fromCache = false,
  bool isStale = false,
  int total = 0,
  bool hasMore = false,
  TransactionQueryFilter filter = const TransactionQueryFilter(),
}) =>
    TransactionsViewState(
      items: items,
      fromCache: fromCache,
      isStale: isStale,
      total: total,
      hasMore: hasMore,
      filter: filter,
    );

void main() {
  // ────────────────────────────────────────────────────
  // TransactionsViewState construction
  // ────────────────────────────────────────────────────
  group('TransactionsViewState construction', () {
    test('stores all fields', () {
      final items = [_tx()];
      const filter = TransactionQueryFilter(type: 'expense');
      final s = _state(
        items: items,
        fromCache: true,
        isStale: true,
        total: 100,
        hasMore: true,
        filter: filter,
      );
      expect(s.items, items);
      expect(s.fromCache, isTrue);
      expect(s.isStale, isTrue);
      expect(s.total, 100);
      expect(s.hasMore, isTrue);
      expect(s.filter, filter);
    });
  });

  // ────────────────────────────────────────────────────
  // copyWith
  // ────────────────────────────────────────────────────
  group('TransactionsViewState.copyWith', () {
    test('preserves all fields when no args passed', () {
      final items = [_tx()];
      final original = _state(items: items, total: 10);
      final copy = original.copyWith();
      expect(copy.items, items);
      expect(copy.total, 10);
      expect(copy.fromCache, original.fromCache);
      expect(copy.hasMore, original.hasMore);
    });

    test('updates items only', () {
      final original = _state(items: [_tx()], total: 1);
      final newItems = [_tx(id: 'tx-2'), _tx(id: 'tx-3')];
      final copy = original.copyWith(items: newItems);
      expect(copy.items, newItems);
      expect(copy.total, 1);
    });

    test('updates total only', () {
      final original = _state(total: 5);
      final copy = original.copyWith(total: 50);
      expect(copy.total, 50);
      expect(copy.items, original.items);
    });

    test('can flip fromCache to true', () {
      final copy = _state().copyWith(fromCache: true);
      expect(copy.fromCache, isTrue);
    });

    test('can flip hasMore to false', () {
      final original = _state(hasMore: true);
      final copy = original.copyWith(hasMore: false);
      expect(copy.hasMore, isFalse);
    });

    test('can update filter', () {
      const newFilter = TransactionQueryFilter(type: 'income', sort: 'date_asc');
      final copy = _state().copyWith(filter: newFilter);
      expect(copy.filter.type, 'income');
      expect(copy.filter.sort, 'date_asc');
    });

    test('can update isStale', () {
      final copy = _state(isStale: false).copyWith(isStale: true);
      expect(copy.isStale, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // hasMore pagination semantics
  // ────────────────────────────────────────────────────
  group('hasMore pagination semantics', () {
    test('hasMore=false means we have all items', () {
      final items = List.generate(5, (i) => _tx(id: 'tx-$i'));
      final s = _state(items: items, total: 5, hasMore: false);
      expect(s.hasMore, isFalse);
      expect(s.items.length, s.total);
    });

    test('hasMore=true means more pages available', () {
      final items = List.generate(10, (i) => _tx(id: 'tx-$i'));
      final s = _state(items: items, total: 100, hasMore: true);
      expect(s.hasMore, isTrue);
      expect(s.items.length, lessThan(s.total));
    });
  });
}
