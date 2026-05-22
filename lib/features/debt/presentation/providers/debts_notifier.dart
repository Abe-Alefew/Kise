import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/debt/data/debt_dto.dart';
import 'package:kise/features/debt/data/debt_repository.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

@immutable
class DebtsViewState {
  final List<DebtEntity> items;
  final DebtSummary? summary;
  final bool fromCache;
  final bool isStale;
  final DebtListFilter filter;

  const DebtsViewState({
    required this.items,
    this.summary,
    required this.fromCache,
    required this.isStale,
    required this.filter,
  });

  double get owedToMe {
    if (summary != null) {
      return summary!.owedToMe;
    }
    return _sumOutstanding(DebtType.lent);
  }

  double get iOwe {
    if (summary != null) {
      return summary!.iOwe;
    }
    return _sumOutstanding(DebtType.borrowed);
  }

  double get netPosition => summary?.netPosition ?? (owedToMe - iOwe);

  double get recoveryRate {
    if (summary != null) {
      return summary!.recoveryRate;
    }
    final total = items.fold<double>(0, (sum, debt) => sum + debt.totalAmount);
    if (total == 0) {
      return 0;
    }
    final paid = items.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    return paid / total;
  }

  double _sumOutstanding(DebtType type) {
    return items
        .where((debt) => debt.type == type && debt.status != DebtStatus.settled)
        .fold<double>(0, (sum, debt) => sum + debt.remaining);
  }

  DebtsViewState copyWith({
    List<DebtEntity>? items,
    DebtSummary? summary,
    bool? fromCache,
    bool? isStale,
    DebtListFilter? filter,
  }) {
    return DebtsViewState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      fromCache: fromCache ?? this.fromCache,
      isStale: isStale ?? this.isStale,
      filter: filter ?? this.filter,
    );
  }
}

class DebtsNotifier extends AsyncNotifier<List<DebtEntity>> {
  DebtListFilter _filter = DebtListFilter.all;
  DebtsViewState? _meta;

  DebtsViewState? get meta => _meta;
  DebtListFilter get filter => _filter;

  @override
  Future<List<DebtEntity>> build() async {
    return _loadDebts(forceRefresh: false);
  }

  Future<List<DebtEntity>> _loadDebts({required bool forceRefresh}) async {
    final repository = ref.read(debtRepositoryProvider);

    final listResult = await repository.getDebts(
      filter: _filter,
      forceRefresh: forceRefresh,
    );

    final summary = await repository.getSummary(forceRefresh: forceRefresh);

    _meta = DebtsViewState(
      items: listResult.items,
      summary: summary,
      fromCache: listResult.fromCache,
      isStale: listResult.isStale,
      filter: _filter,
    );

    return listResult.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadDebts(forceRefresh: true));
  }

  Future<void> applyUiFilter(String uiLabel) async {
    _filter = DebtListFilterX.fromUiLabel(uiLabel);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadDebts(forceRefresh: false));
  }

  List<DebtEntity> get filteredItems {
    final items = state.value ?? [];

    switch (_filter) {
      case DebtListFilter.active:
        return items
            .where((debt) => debt.status != DebtStatus.settled)
            .toList();
      case DebtListFilter.lent:
        return items.where((debt) => debt.type == DebtType.lent).toList();
      case DebtListFilter.borrowed:
        return items
            .where((debt) => debt.type == DebtType.borrowed)
            .toList();
      case DebtListFilter.settled:
        return items
            .where((debt) => debt.status == DebtStatus.settled)
            .toList();
      case DebtListFilter.all:
        return items;
    }
  }

  Future<DebtEntity> addDebt({
    required String personName,
    required DebtType type,
    required double totalAmount,
    required DateTime debtDate,
    String? notes,
  }) async {
    final repository = ref.read(debtRepositoryProvider);
    final currentList = state.value ?? [];

    final optimisticId = 'optimistic-${DateTime.now().microsecondsSinceEpoch}';
    final isoDate = DebtDateParser.toIsoDate(debtDate);

    final optimistic = DebtEntity(
      id: optimisticId,
      personName: personName.trim(),
      personInitial:
          personName.trim().isNotEmpty ? personName.trim()[0].toUpperCase() : '?',
      type: type,
      totalAmount: totalAmount,
      paidAmount: 0,
      remaining: totalAmount,
      debtDate: isoDate,
      date: debtDate,
      notes: notes,
      payments: const [],
      status: DebtStatus.pending,
      isDirty: true,
    );

    state = AsyncData([optimistic, ...currentList]);

    try {
      final created = await repository.createDebt(
        CreateDebtInput(
          personName: personName.trim(),
          type: type,
          totalAmount: totalAmount,
          debtDate: isoDate,
          notes: notes,
        ),
      );

      final updatedList = [
        created,
        ...currentList.where((debt) => debt.id != optimisticId),
      ];

      state = AsyncData(updatedList);

      final summary = await repository.getSummary(forceRefresh: false);
      _meta = _meta?.copyWith(items: updatedList, summary: summary) ??
          DebtsViewState(
            items: updatedList,
            summary: summary,
            fromCache: true,
            isStale: false,
            filter: _filter,
          );

      return created;
    } on ApiException catch (error) {
      final failed = optimistic.copyWith(syncError: error.message);
      state = AsyncData([failed, ...currentList]);
      rethrow;
    } catch (error) {
      final failed = optimistic.copyWith(syncError: error.toString());
      state = AsyncData([failed, ...currentList]);
      rethrow;
    }
  }

  Future<DebtEntity> recordPayment({
    required DebtEntity debt,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final repository = ref.read(debtRepositoryProvider);
    final currentList = state.value ?? [];
    final isoPaymentDate = DebtDateParser.toIsoDate(paymentDate);

    final optimisticPayment = PaymentRecord(
      id: 'optimistic-payment-${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      date: paymentDate,
      notes: notes,
      paymentDate: isoPaymentDate,
      isDirty: true,
    );

    final nextPaid = debt.paidAmount + amount;
    final nextRemaining =
        (debt.totalAmount - nextPaid).clamp(0.0, double.infinity);
    final nextStatus = nextPaid >= debt.totalAmount
        ? DebtStatus.settled
        : nextPaid > 0
            ? DebtStatus.partial
            : DebtStatus.pending;

    final optimisticDebt = debt.copyWith(
      paidAmount: nextPaid,
      remaining: nextRemaining,
      payments: [...debt.payments, optimisticPayment],
      status: nextStatus,
      isDirty: true,
      clearSyncError: true,
    );

    state = AsyncData(
      currentList
          .map((item) => item.id == debt.id ? optimisticDebt : item)
          .toList(),
    );

    try {
      final synced = await repository.recordPayment(
        debt.id,
        RecordPaymentInput(
          amount: amount,
          paymentDate: isoPaymentDate,
          notes: notes,
        ),
      );

      final syncedList = currentList
          .map((item) => item.id == debt.id ? synced : item)
          .toList();

      state = AsyncData(syncedList);

      final summary = await repository.getSummary(forceRefresh: false);
      _meta = _meta?.copyWith(items: syncedList, summary: summary);

      return synced;
    } on ApiException catch (error) {
      final failed = optimisticDebt.copyWith(syncError: error.message);
      state = AsyncData(
        currentList
            .map((item) => item.id == debt.id ? failed : item)
            .toList(),
      );
      rethrow;
    } catch (error) {
      final failed = optimisticDebt.copyWith(syncError: error.toString());
      state = AsyncData(
        currentList
            .map((item) => item.id == debt.id ? failed : item)
            .toList(),
      );
      rethrow;
    }
  }

  Future<DebtEntity> updateDebt(
    String debtId,
    UpdateDebtInput input,
  ) async {
    final repository = ref.read(debtRepositoryProvider);
    final currentList = state.value ?? [];

    final updated = await repository.updateDebt(debtId, input);
    final syncedList =
        currentList.map((debt) => debt.id == debtId ? updated : debt).toList();

    state = AsyncData(syncedList);

    final summary = await repository.getSummary(forceRefresh: false);
    _meta = _meta?.copyWith(items: syncedList, summary: summary);

    return updated;
  }

  Future<void> removeDebt(String debtId) async {
    final repository = ref.read(debtRepositoryProvider);
    await repository.deleteDebt(debtId);

    final currentList = state.value ?? [];
    final updatedList =
        currentList.where((debt) => debt.id != debtId).toList();

    state = AsyncData(updatedList);

    final summary = await repository.getSummary(forceRefresh: false);
    _meta = _meta?.copyWith(items: updatedList, summary: summary);
  }
}

final debtsNotifierProvider =
    AsyncNotifierProvider<DebtsNotifier, List<DebtEntity>>(
  DebtsNotifier.new,
);

final debtsMetaProvider = Provider<DebtsViewState?>((ref) {
  ref.watch(debtsNotifierProvider);
  return ref.read(debtsNotifierProvider.notifier).meta;
});