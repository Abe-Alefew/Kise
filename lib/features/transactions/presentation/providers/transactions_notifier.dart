import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/transactions/data/transaction_repository.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';

@immutable
class TransactionsViewState {
  final List<TransactionEntity> items;
  final bool fromCache;
  final bool isStale;
  final int total;
  final bool hasMore;
  final TransactionQueryFilter filter;

  const TransactionsViewState({
    required this.items,
    required this.fromCache,
    required this.isStale,
    required this.total,
    required this.hasMore,
    required this.filter,
  });

  TransactionsViewState copyWith({
    List<TransactionEntity>? items,
    bool? fromCache,
    bool? isStale,
    int? total,
    bool? hasMore,
    TransactionQueryFilter? filter,
  }) {
    return TransactionsViewState(
      items: items ?? this.items,
      fromCache: fromCache ?? this.fromCache,
      isStale: isStale ?? this.isStale,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
    );
  }
}

class TransactionsNotifier extends AsyncNotifier<List<TransactionEntity>> {
  TransactionQueryFilter _filter = const TransactionQueryFilter();
  TransactionsViewState? _meta;

  TransactionsViewState? get meta => _meta;

  TransactionQueryFilter get filter => _filter;

  @override
  Future<List<TransactionEntity>> build() async {
    return _loadTransactions(forceRefresh: false);
  }

  Future<List<TransactionEntity>> _loadTransactions({
    required bool forceRefresh,
  }) async {
    final repository = ref.read(transactionRepositoryProvider);

    final result = await repository.getTransactions(
      filter: _filter,
      forceRefresh: forceRefresh,
    );

    _meta = TransactionsViewState(
      items: result.items,
      fromCache: result.fromCache,
      isStale: result.isStale,
      total: result.total,
      hasMore: result.hasMore,
      filter: _filter,
    );

    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadTransactions(forceRefresh: true),
    );
  }

  Future<void> applyFilter(TransactionQueryFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadTransactions(forceRefresh: false),
    );
  }

  void updateTypeFilter(String typeLabel) {
    final normalizedType = typeLabel == 'All' ? null : typeLabel;
    applyFilter(
      _filter.copyWith(
        type: normalizedType,
        offset: 0,
      ),
    );
  }

  void updateSearchQuery(String query) {
    applyFilter(
      _filter.copyWith(
        searchQuery: query,
        offset: 0,
      ),
    );
  }

  void updateSort(String sort) {
    applyFilter(
      _filter.copyWith(
        sort: sort,
        offset: 0,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    final metaState = _meta;

    if (current == null || metaState == null || !metaState.hasMore) {
      return;
    }

    final nextFilter = _filter.copyWith(
      offset: current.length,
      limit: _filter.limit ?? 20,
    );

    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.getTransactions(
      filter: nextFilter,
      forceRefresh: false,
    );

    final merged = [...current, ...result.items];

    _filter = nextFilter.copyWith(offset: 0);
    _meta = metaState.copyWith(
      items: merged,
      total: result.total,
      hasMore: merged.length < result.total,
    );

    state = AsyncData(merged);
  }

  Future<TransactionEntity> addTransaction(CreateTransactionInput input) async {
    final repository = ref.read(transactionRepositoryProvider);
    final current = state.value ?? [];

    final optimistic = TransactionEntity.optimisticFromInput(input);
    state = AsyncData([optimistic, ...current]);

    try {
      final created = await repository.createTransaction(input);

      final updatedList = [
        created,
        ...current.where((item) => item.id != optimistic.id),
      ];

      _meta = _meta?.copyWith(
            items: updatedList,
            total: (_meta?.total ?? updatedList.length) + 1,
          ) ??
          TransactionsViewState(
            items: updatedList,
            fromCache: true,
            isStale: false,
            total: updatedList.length,
            hasMore: false,
            filter: _filter,
          );

      state = AsyncData(updatedList);
      return created;
    } on ApiException catch (error) {
      final failedOptimistic = optimistic.copyWith(
        isDirty: true,
        syncError: error.message,
      );

      final updatedList = [
        failedOptimistic,
        ...current,
      ];

      state = AsyncData(updatedList);
      rethrow;
    } catch (error) {
      final failedOptimistic = optimistic.copyWith(
        isDirty: true,
        syncError: error.toString(),
      );

      final updatedList = [
        failedOptimistic,
        ...current,
      ];

      state = AsyncData(updatedList);
      rethrow;
    }
  }

  void removeLocalTransaction(String transactionId) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final updated = current.where((item) => item.id != transactionId).toList();
    state = AsyncData(updated);

    _meta = _meta?.copyWith(
      items: updated,
      total: (_meta?.total ?? updated.length) - 1,
    );
  }
}

final transactionsNotifierProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionEntity>>(
  TransactionsNotifier.new,
);

final transactionsMetaProvider = Provider<TransactionsViewState?>((ref) {
  ref.watch(transactionsNotifierProvider);
  return ref.read(transactionsNotifierProvider.notifier).meta;
});