import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
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
    final auth = ref.watch(authStateProvider);
    if (auth?.isAuthenticated != true || auth?.user == null) {
      return [];
    }

    // Re-fetch when the signed-in user changes (logout/login).
    ref.watch(authStateProvider.select((state) => state?.user?.id));

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

  Future<List<GoalEntity>> _reloadState({bool forceRefresh = false}) async {
    final items = await _loadGoals(forceRefresh: forceRefresh);
    state = AsyncData(items);
    return items;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadGoals(forceRefresh: true));
  }

  Future<void> applyUiFilter(String uiLabel) async {
    _filter = GoalStatusFilterX.fromUiLabel(uiLabel);
    state = await AsyncValue.guard(() => _loadGoals(forceRefresh: false));
  }

  List<GoalEntity> get filteredItems {
    final items = state.value ?? [];
    return items.where(_filter.matches).toList();
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

    final parsedDue =
        GoalDateParser.parseDueDate(dueDateDisplay) ?? DateTime.now();
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

      await _reloadState();
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

      await _reloadState();
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

    final updated = await repository.updateGoal(goalId, input);
    await _reloadState();
    return updated;
  }

  Future<void> deleteGoal(String goalId) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.deleteGoal(goalId);
    await _reloadState();
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
