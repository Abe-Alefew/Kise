import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
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

  /// Re-sync UI from server/cache after a failed mutation (clears dirty rows).
  Future<void> _revertAfterFailure() async {
    try {
      await _reloadState(forceRefresh: true);
    } catch (_) {
      // Keep prior list if refresh also fails.
    }
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

    final parsedDue =
        GoalDateParser.parseDueDate(dueDateDisplay) ?? DateTime.now();
    final isoDueDate = GoalDateParser.toIsoDate(parsedDue);
    final normalizedPeriod = GoalDateParser.normalizePeriod(period);

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
    } catch (error) {
      await _revertAfterFailure();
      rethrow;
    }
  }

  Future<GoalEntity> logDeposit({
    required GoalEntity goal,
    required double amount,
    required String source,
    String? accountId,
  }) async {
    if (goal.isLocked) {
      throw const ApiException(
        message: 'Deposits cannot be added to a locked goal',
        code: 'BUSINESS_RULE',
        statusCode: 422,
      );
    }

    final repository = ref.read(goalRepositoryProvider);

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
    } catch (error) {
      await _revertAfterFailure();
      rethrow;
    }
  }

  Future<GoalEntity> updateGoal(
    String goalId,
    UpdateGoalInput input,
  ) async {
    final repository = ref.read(goalRepositoryProvider);

    try {
      final updated = await repository.updateGoal(goalId, input);
      await _reloadState();
      return updated;
    } catch (error) {
      await _revertAfterFailure();
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final repository = ref.read(goalRepositoryProvider);

    try {
      await repository.deleteGoal(goalId);
      await _reloadState();
    } catch (error) {
      await _revertAfterFailure();
      rethrow;
    }
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
