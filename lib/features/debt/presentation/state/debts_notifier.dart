import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/debt/data/dtos/debt_dto.dart';
import 'package:kise/features/debt/data/repositories/debt_repository.dart';
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

  /// Total lent minus total borrowed (includes settled records).
  double get adjustedNetPosition {
    var totalLent = 0.0;
    var totalBorrowed = 0.0;
    for (final debt in items) {
      if (debt.type == DebtType.lent) {
        totalLent += debt.totalAmount;
      } else {
        totalBorrowed += debt.totalAmount;
      }
    }
    return totalLent - totalBorrowed;
  }

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

class DebtsMetaNotifier extends Notifier<DebtsViewState?> {
  @override
  DebtsViewState? build() => null;
}

final debtsMetaProvider =
    NotifierProvider<DebtsMetaNotifier, DebtsViewState?>(
  DebtsMetaNotifier.new,
);

class DebtsNotifier extends AsyncNotifier<List<DebtEntity>> {
  DebtListFilter _filter = DebtListFilter.all;
  DebtsViewState? _meta;

  DebtsViewState? get meta => _meta;
  DebtListFilter get filter => _filter;

  @override
  Future<List<DebtEntity>> build() async {
    return _loadDebts(forceRefresh: false);
  }

  void _publishMeta(DebtsViewState meta) {
    _meta = meta;
    ref.read(debtsMetaProvider.notifier).state = meta;
  }

  Future<List<DebtEntity>> _loadDebts({required bool forceRefresh}) async {
    final repository = ref.read(debtRepositoryProvider);

    final listResult = await repository.getDebts(
      filter: _filter,
      forceRefresh: forceRefresh,
    );

    final summary = await repository.getSummary(forceRefresh: forceRefresh);

    final meta = DebtsViewState(
      items: listResult.items,
      summary: summary,
      fromCache: listResult.fromCache,
      isStale: listResult.isStale,
      filter: _filter,
    );

    _publishMeta(meta);
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

  void _rejectPendingSyncId(String debtId) {
    if (isPendingSyncDebtId(debtId)) {
      throw const ApiException(
        message: 'Debt is still syncing. Please try again in a moment.',
        code: 'PENDING_SYNC',
        statusCode: 409,
      );
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
    final currentList = List<DebtEntity>.from(state.value ?? []);
    final isoDate = DebtDateParser.toIsoDate(debtDate);

    final optimisticId = 'optimistic-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = DebtEntity(
      id: optimisticId,
      personName: personName.trim(),
      personInitial: personName.trim().isNotEmpty
          ? personName.trim()[0].toUpperCase()
          : '?',
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
      await repository.createDebt(
        CreateDebtInput(
          personName: personName.trim(),
          type: type,
          totalAmount: totalAmount,
          debtDate: isoDate,
          notes: notes,
        ),
      );

      await refresh();
      final items = state.value ?? [];
      return items.firstWhere(
        (debt) =>
            debt.personName == personName.trim() &&
            debt.debtDate == isoDate &&
            debt.totalAmount == totalAmount,
        orElse: () => items.first,
      );
    } on ApiException {
      state = AsyncData(currentList);
      rethrow;
    } catch (error) {
      state = AsyncData(currentList);
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<DebtEntity> recordPayment({
    required DebtEntity debt,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    _rejectPendingSyncId(debt.id);

    final repository = ref.read(debtRepositoryProvider);
    final currentList = List<DebtEntity>.from(state.value ?? []);
    final isoPaymentDate = DebtDateParser.toIsoDate(paymentDate);

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
      await repository.recordPayment(
        debt.id,
        RecordPaymentInput(
          amount: amount,
          paymentDate: isoPaymentDate,
          notes: notes,
        ),
      );

      await refresh();
      final items = state.value ?? [];
      return items.firstWhere(
        (item) => item.id == debt.id,
        orElse: () => optimisticDebt,
      );
    } on ApiException {
      state = AsyncData(currentList);
      rethrow;
    } catch (error) {
      state = AsyncData(currentList);
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<DebtEntity> updateDebt(
    String debtId,
    UpdateDebtInput input,
  ) async {
    _rejectPendingSyncId(debtId);

    final repository = ref.read(debtRepositoryProvider);
    final currentList = List<DebtEntity>.from(state.value ?? []);

    try {
      final updated = await repository.updateDebt(debtId, input);
      await refresh();
      final items = state.value ?? [];
      return items.firstWhere(
        (debt) => debt.id == updated.id,
        orElse: () => updated,
      );
    } on ApiException {
      state = AsyncData(currentList);
      rethrow;
    } catch (error) {
      state = AsyncData(currentList);
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<void> removeDebt(String debtId) async {
    _rejectPendingSyncId(debtId);

    final repository = ref.read(debtRepositoryProvider);
    final currentList = List<DebtEntity>.from(state.value ?? []);
    final optimisticList =
        currentList.where((debt) => debt.id != debtId).toList();

    state = AsyncData(optimisticList);

    try {
      await repository.deleteDebt(debtId);
      await refresh();
    } on ApiException {
      state = AsyncData(currentList);
      rethrow;
    } catch (error) {
      state = AsyncData(currentList);
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}

final debtsNotifierProvider =
    AsyncNotifierProvider<DebtsNotifier, List<DebtEntity>>(
  DebtsNotifier.new,
);
