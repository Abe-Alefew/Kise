import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';
import 'package:kise/features/home/presentation/state/home_dashboard_notifier.dart';
import 'package:kise/features/transactions/presentation/state/transactions_analytics_provider.dart';
import 'package:kise/features/transactions/presentation/state/transactions_summary_provider.dart';

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
    state = await AsyncValue.guard(
      () => _loadTransactions(forceRefresh: true),
    );
  }

  void _reloadDependents() {
    unawaited(ref.refresh(currentMonthSummaryProvider.future));
    ref.invalidate(transactionAnalyticsProvider);
    ref.invalidate(homeDashboardProvider);
  }

  Future<void> _syncListInBackground() async {
    final previous = state.value ?? const <TransactionEntity>[];
    try {
      final items = await _loadTransactions(forceRefresh: true);
      state = AsyncData(items);
    } catch (_) {
      if (previous.isNotEmpty) {
        state = AsyncData(previous);
      }
    }
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
      limit: _filter.limit,
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

    // Only show the optimistic item if it matches the active type filter.
    // Avoids injecting e.g. an Income transaction into an Expense-filtered list.
    final matchesFilter =
        _filter.type == null || _filter.type == optimistic.type;

    if (matchesFilter) {
      state = AsyncData([optimistic, ...current]);
    }

    try {
      final created = await repository.createTransaction(input);

      if (matchesFilter) {
        final updatedList = [
          created,
          ...current.where((item) => item.id != optimistic.id),
        ];

        _meta = _meta?.copyWith(
              items: updatedList,
              total: (_meta?.total ?? current.length) + 1,
            ) ??
            TransactionsViewState(
              items: updatedList,
              fromCache: false,
              isStale: false,
              total: updatedList.length,
              hasMore: false,
              filter: _filter,
            );

        state = AsyncData(updatedList);
      } else {
        _meta = _meta?.copyWith(total: (_meta?.total ?? current.length) + 1);
      }

      _reloadDependents();
      unawaited(_syncListInBackground());

      return created;
    } on ApiException {
      if (matchesFilter) state = AsyncData(current);
      rethrow;
    } catch (error) {
      if (matchesFilter) state = AsyncData(current);
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<TransactionEntity> updateTransaction(
    String transactionId,
    UpdateTransactionInput input,
  ) async {
    final repository = ref.read(transactionRepositoryProvider);
    final current = state.value ?? [];

    try {
      final updated = await repository.updateTransaction(
        transactionId,
        input.toJson(),
      );

      _applyUpdatedTransaction(updated, previousLength: current.length);
      _reloadDependents();
      unawaited(_syncListInBackground());

      return updated;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final repository = ref.read(transactionRepositoryProvider);
    final current = state.value ?? [];
    final previous = List<TransactionEntity>.from(current);

    final optimistic =
        current.where((item) => item.id != transactionId).toList();
    state = AsyncData(optimistic);
    _meta = _meta?.copyWith(
      items: optimistic,
      total: (_meta?.total ?? optimistic.length + 1) - 1,
    );

    try {
      await repository.deleteTransaction(transactionId);
      _reloadDependents();
      unawaited(_syncListInBackground());
    } on ApiException {
      state = AsyncData(previous);
      _meta = _meta?.copyWith(
        items: previous,
        total: (_meta?.total ?? previous.length),
      );
      rethrow;
    } catch (error) {
      state = AsyncData(previous);
      _meta = _meta?.copyWith(
        items: previous,
        total: (_meta?.total ?? previous.length),
      );
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  void _applyUpdatedTransaction(
    TransactionEntity updated, {
    required int previousLength,
  }) {
    final current = state.value ?? [];

    final matchesFilter =
        _filter.type == null || _filter.type == updated.type;

    final bool wasInList = current.any((item) => item.id == updated.id);

    final List<TransactionEntity> next;
    if (matchesFilter) {
      if (wasInList) {
        next = current
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      } else {
        next = [updated, ...current];
      }
    } else {
      next = current.where((item) => item.id != updated.id).toList();
    }

    state = AsyncData(next);
    _meta = _meta?.copyWith(
      items: next,
      total: wasInList ? _meta?.total : (_meta?.total ?? previousLength) + 1,
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