import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/goals/data/goal_dto.dart';
import 'package:kise/features/goals/data/goal_repository.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

@immutable
class GoalsViewState {
  final List<GoalEntity> items;
  final bool fromCache;
  final bool isStale;
  final GoalStatusFilter filter;

  const GoalsViewState({
    required this.items,
    required this.fromCache,
    required this.isStale,
    required this.filter,
  });

  GoalsViewState copyWith({
    List<GoalEntity>? items,
    bool? fromCache,
    bool? isStale,
    GoalStatusFilter? filter,
  }) {
    return GoalsViewState(
      items: items ?? this.items,
      fromCache: fromCache ?? this.fromCache,
      isStale: isStale ?? this.isStale,
      filter: filter ?? this.filter,
    );
  }
}

class GoalsNotifier extends AsyncNotifier<List<GoalEntity>> {
  GoalStatusFilter _filter = GoalStatusFilter.all;
  GoalsViewState? _meta;

  GoalsViewState? get meta => _meta;
  GoalStatusFilter get filter => _filter;

  @override
  Future<List<GoalEntity>> build() async {
    return _loadGoals(forceRefresh: false);
  }

  Future<List<GoalEntity>> _loadGoals({required bool forceRefresh}) async {
    final repository = ref.read(goalRepositoryProvider);
    final result = await repository.getGoals(
      status: _filter,
      forceRefresh: forceRefresh,
    );

    _meta = GoalsViewState(
      items: result.items,
      fromCache: result.fromCache,
      isStale: result.isStale,
      filter: _filter,
    );

    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadGoals(forceRefresh: true));
  }

  Future<void> applyUiFilter(String uiLabel) async {
    _filter = GoalStatusFilterX.fromUiLabel(uiLabel);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadGoals(forceRefresh: false));
  }

  List<GoalEntity> get filteredItems {
    final items = state.value ?? [];
    if (_filter == GoalStatusFilter.all) {
      return items;
    }
    return items.where((goal) => goal.status == _filter.apiValue).toList();
  }

  Future<GoalEntity> addGoal({
    required String title,
    required String period,
    required double targetAmount,
    required double currentAmount,
    required String dueDateDisplay,
    String? note,
  }) async {
    final repository = ref.read(goalRepositoryProvider);
    final currentList = state.value ?? [];

    final parsedDue = GoalDateParser.parseDueDate(dueDateDisplay) ?? DateTime.now();
    final isoDueDate = GoalDateParser.toIsoDate(parsedDue);
    final normalizedPeriod = GoalDateParser.normalizePeriod(period);

    final optimisticId = 'optimistic-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = GoalEntity(
      id: optimisticId,
      title: title.trim(),
      period: normalizedPeriod,
      dueDate: isoDueDate,
      dueDateDisplay: dueDateDisplay,
      currentAmount: currentAmount,
      targetAmount: targetAmount,
      progress: GoalDto.computeProgress(currentAmount, targetAmount),
      isCompleted: currentAmount >= targetAmount,
      isLocked: false,
      status: currentAmount >= targetAmount ? 'completed' : 'active',
      note: note,
      isDirty: true,
    );

    state = AsyncData([optimistic, ...currentList]);

    try {
      final created = await repository.createGoal(
        CreateGoalInput(
          title: title.trim(),
          period: normalizedPeriod,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          dueDate: isoDueDate,
          note: note,
        ),
      );

      final updatedList = [
        created,
        ...currentList.where((goal) => goal.id != optimisticId),
      ];

      state = AsyncData(updatedList);
      _meta = _meta?.copyWith(items: updatedList) ??
          GoalsViewState(
            items: updatedList,
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

  Future<GoalEntity> logDeposit({
    required GoalEntity goal,
    required double amount,
    required String source,
    String? accountId,
  }) async {
    final repository = ref.read(goalRepositoryProvider);
    final currentList = state.value ?? [];

    final optimisticGoal = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      progress: GoalDto.computeProgress(
        goal.currentAmount + amount,
        goal.targetAmount,
      ),
      isCompleted: goal.currentAmount + amount >= goal.targetAmount,
      status: goal.currentAmount + amount >= goal.targetAmount
          ? 'completed'
          : goal.status,
      isDirty: true,
      clearSyncError: true,
    );

    state = AsyncData(
      currentList
          .map((item) => item.id == goal.id ? optimisticGoal : item)
          .toList(),
    );

    try {
      final result = await repository.logDeposit(
        goal.id,
        LogDepositInput(
          amount: amount,
          source: source,
          accountId: accountId,
        ),
      );

      final syncedList = currentList
          .map((item) => item.id == goal.id ? result.goal : item)
          .toList();

      state = AsyncData(syncedList);
      _meta = _meta?.copyWith(items: syncedList);

      return result.goal;
    } on ApiException catch (error) {
      final failed = optimisticGoal.copyWith(syncError: error.message);
      state = AsyncData(
        currentList
            .map((item) => item.id == goal.id ? failed : item)
            .toList(),
      );
      rethrow;
    } catch (error) {
      final failed = optimisticGoal.copyWith(syncError: error.toString());
      state = AsyncData(
        currentList
            .map((item) => item.id == goal.id ? failed : item)
            .toList(),
      );
      rethrow;
    }
  }

  Future<GoalEntity> updateGoal(
    String goalId,
    UpdateGoalInput input,
  ) async {
    final repository = ref.read(goalRepositoryProvider);
    final currentList = state.value ?? [];

    final updated = await repository.updateGoal(goalId, input);
    final syncedList =
        currentList.map((goal) => goal.id == goalId ? updated : goal).toList();

    state = AsyncData(syncedList);
    _meta = _meta?.copyWith(items: syncedList);

    return updated;
  }

  Future<void> deleteGoal(String goalId) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.deleteGoal(goalId);

    final currentList = state.value ?? [];
    final updatedList =
        currentList.where((goal) => goal.id != goalId).toList();

    state = AsyncData(updatedList);
    _meta = _meta?.copyWith(items: updatedList);
  }

  Future<GoalEntity> toggleLock(GoalEntity goal) async {
    return updateGoal(
      goal.id,
      UpdateGoalInput(isLocked: !goal.isLocked),
    );
  }
}

final goalsNotifierProvider =
    AsyncNotifierProvider<GoalsNotifier, List<GoalEntity>>(
  GoalsNotifier.new,
);

final goalsMetaProvider = Provider<GoalsViewState?>((ref) {
  ref.watch(goalsNotifierProvider);
  return ref.read(goalsNotifierProvider.notifier).meta;
});