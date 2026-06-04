// Tests for TransactionsNotifier — initial load, type filter updates,
// search query updates, sort changes, and optimistic add/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';
import 'package:kise/features/transactions/presentation/state/transactions_notifier.dart';

import '../helpers/provider_helper.dart';
import '../helpers/test_data/transaction_fixtures.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockTransactionRepository extends Mock implements TransactionRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

TransactionListResult _result(List<TransactionEntity> items) =>
    TransactionListResult(
      items: items,
      fromCache: false,
      isStale: false,
      total: items.length,
      hasMore: false,
    );

TransactionSummary _emptySummary() => const TransactionSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      savingRate: 0,
      currency: 'ETB',
    );

TransactionAnalytics _emptyAnalytics() => TransactionAnalytics.fromJson({});

/// Simple container — only overrides the transaction repo.
/// ref.invalidate(homeDashboardProvider) from _reloadDependents is lazy and
/// harmless when nothing in the test reads that provider.
ProviderContainer _makeContainer(MockTransactionRepository txRepo) {
  return createContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(txRepo),
    ],
  );
}

void _stubFull(MockTransactionRepository repo, List<TransactionEntity> items) {
  when(() => repo.getTransactions(
        filter: any(named: 'filter'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => _result(items));
  when(() => repo.getSummary(
        from: any(named: 'from'),
        to: any(named: 'to'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => _emptySummary());
  when(() => repo.getAnalytics(
        range: any(named: 'range'),
        type: any(named: 'type'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => _emptyAnalytics());
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    registerFallbackValue(const CreateTransactionInput(
      type: 'expense',
      title: 'Test',
      category: 'Food',
      amount: 10,
      transactionDate: '2025-06-01',
    ));
    // TransactionQueryFilter is a class used with any() — must register fallback.
    registerFallbackValue(const TransactionQueryFilter());
  });

  // ────────────────────────────────────────────────────
  // Initial load
  // ────────────────────────────────────────────────────
  group('initial load', () {
    test('state is AsyncLoading then AsyncData', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      expect(container.read(transactionsNotifierProvider), isA<AsyncLoading>());
      await container.read(transactionsNotifierProvider.future);
      expect(container.read(transactionsNotifierProvider), isA<AsyncData>());
    });

    test('loads transactions from repository', () async {
      _stubFull(mockRepo, [incomeTransaction, expenseTransaction]);
      final container = _makeContainer(mockRepo);
      final txs = await container.read(transactionsNotifierProvider.future);
      expect(txs, hasLength(2));
    });

    test('meta contains total count after load', () async {
      _stubFull(mockRepo, [incomeTransaction]);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);
      final meta = container.read(transactionsMetaProvider);
      expect(meta?.total, 1);
    });

    test('defaults filter sort to date_desc', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);
      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.sort, 'date_desc');
    });
  });

  // ────────────────────────────────────────────────────
  // updateTypeFilter()
  // ────────────────────────────────────────────────────
  group('updateTypeFilter()', () {
    test('sets filter.type to "Income"', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateTypeFilter('Income');

      // Give the async applyFilter a tick to update
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.type, 'Income');
    });

    test('sets filter.type to null for "All"', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateTypeFilter('All');
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.type, isNull);
    });

    test('resets offset to 0 when changing type', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateTypeFilter('Expense');
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.offset, 0);
    });
  });

  // ────────────────────────────────────────────────────
  // updateSearchQuery()
  // ────────────────────────────────────────────────────
  group('updateSearchQuery()', () {
    test('sets filter.searchQuery', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateSearchQuery('coffee');
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.searchQuery, 'coffee');
    });

    test('empty query sets searchQuery', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateSearchQuery('');
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.searchQuery, '');
    });
  });

  // ────────────────────────────────────────────────────
  // updateSort()
  // ────────────────────────────────────────────────────
  group('updateSort()', () {
    test('changes filter.sort to date_asc', () async {
      _stubFull(mockRepo, []);
      final container = _makeContainer(mockRepo);
      await container.read(transactionsNotifierProvider.future);

      container
          .read(transactionsNotifierProvider.notifier)
          .updateSort('date_asc');
      await Future<void>.delayed(Duration.zero);

      final filter =
          container.read(transactionsNotifierProvider.notifier).filter;
      expect(filter.sort, 'date_asc');
    });
  });

  // ────────────────────────────────────────────────────
  // optimistic add — TransactionEntity.optimisticFromInput
  // ────────────────────────────────────────────────────
  group('optimistic add sanity check', () {
    test('optimisticFromInput produces a dirty entity', () {
      const input = CreateTransactionInput(
        type: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 5000,
        transactionDate: '2025-06-01',
      );
      final entity = TransactionEntity.optimisticFromInput(input);
      expect(entity.isDirty, isTrue);
      expect(entity.id, isNotEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionsViewState
  // ────────────────────────────────────────────────────
  group('TransactionsViewState copyWith', () {
    test('preserves all fields when no args', () {
      const s = TransactionsViewState(
        items: [],
        fromCache: false,
        isStale: false,
        total: 10,
        hasMore: true,
        filter: TransactionQueryFilter(),
      );
      final copy = s.copyWith();
      expect(copy.total, 10);
      expect(copy.hasMore, isTrue);
    });

    test('updates total independently', () {
      const s = TransactionsViewState(
        items: [],
        fromCache: false,
        isStale: false,
        total: 5,
        hasMore: false,
        filter: TransactionQueryFilter(),
      );
      expect(s.copyWith(total: 50).total, 50);
    });
  });
}
