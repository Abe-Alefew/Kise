// Tests for GoalsNotifier — auth guard (unauthenticated returns empty list),
// initial load with goals, filteredItems per GoalStatusFilter, applyUiFilter(),
// and GoalsViewState model.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/goals/data/repositories/goal_repository.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';
import 'package:kise/features/goals/presentation/state/goals_notifier.dart';

import '../helpers/provider_helper.dart';
import '../helpers/test_data/auth_fixtures.dart';
import '../helpers/test_data/goal_fixtures.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGoalRepository extends Mock implements GoalRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

GoalListResult _result(List<GoalEntity> items) =>
    GoalListResult(items: items, fromCache: false, isStale: false);

/// Overrides authStateProvider directly (synchronous) rather than going through
/// the async AuthNotifier chain, so GoalsNotifier.build() sees auth immediately.
ProviderContainer _makeContainer({
  required MockGoalRepository goalRepo,
  bool authenticated = true,
}) {
  final authState = authenticated ? authenticatedState : unauthenticatedState;
  return createContainer(
    overrides: [
      goalRepositoryProvider.overrideWithValue(goalRepo),
      // Override the derived Provider directly so it's synchronously readable.
      authStateProvider.overrideWith((ref) => authState),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockGoalRepository mockRepo;

  setUp(() {
    mockRepo = MockGoalRepository();
    registerFallbackValue(const CreateGoalInput(
      title: 'Test',
      period: 'monthly',
      targetAmount: 1000,
      dueDate: '2025-12-31',
    ));
    registerFallbackValue(const UpdateGoalInput());
    registerFallbackValue(const LogDepositInput(amount: 100, source: 'cash'));
    // Enum types used with any() require fallback value registration.
    registerFallbackValue(GoalStatusFilter.all);
  });

  // ────────────────────────────────────────────────────
  // Auth guard
  // ────────────────────────────────────────────────────
  group('auth guard', () {
    test('returns empty list when user is unauthenticated', () async {
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: false,
      );
      final goals = await container.read(goalsNotifierProvider.future);
      expect(goals, isEmpty);
      verifyNever(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          ));
    });
  });

  // ────────────────────────────────────────────────────
  // Initial load — authenticated
  // ────────────────────────────────────────────────────
  group('initial load — authenticated', () {
    setUp(() {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => _result([]));
    });

    test('state is AsyncLoading then resolves to AsyncData', () async {
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      expect(container.read(goalsNotifierProvider), isA<AsyncLoading>());
      await container.read(goalsNotifierProvider.future);
      expect(container.read(goalsNotifierProvider), isA<AsyncData>());
    });

    test('loads goals from repository', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => _result([activeGoal, completedGoal]));

      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      final goals = await container.read(goalsNotifierProvider.future);
      expect(goals, hasLength(2));
    });

    test('meta is published after load', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => _result([activeGoal]));

      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);
      final meta = container.read(goalsMetaProvider);
      expect(meta, isNotNull);
      expect(meta!.items, hasLength(1));
    });
  });

  // ────────────────────────────────────────────────────
  // filteredItems — GoalStatusFilter.all
  // ────────────────────────────────────────────────────
  group('filteredItems — all', () {
    test('returns every goal in state', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer(
        (_) async => _result([activeGoal, completedGoal, canceledGoal]),
      );
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      final filtered =
          container.read(goalsNotifierProvider.notifier).filteredItems;
      expect(filtered, hasLength(3));
    });
  });

  // ────────────────────────────────────────────────────
  // filteredItems — GoalStatusFilter.active
  // ────────────────────────────────────────────────────
  group('filteredItems — active', () {
    test('returns only active goals with current < target', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer(
        (_) async =>
            _result([activeGoal, completedGoal, canceledGoal, lockedGoal]),
      );
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      await container
          .read(goalsNotifierProvider.notifier)
          .applyUiFilter('Active');

      final filtered =
          container.read(goalsNotifierProvider.notifier).filteredItems;
      // activeGoal (status='active', current<target) + lockedGoal (same)
      expect(filtered.every((g) => g.status == 'active'), isTrue);
      expect(
        filtered.every((g) => g.currentAmount < g.targetAmount),
        isTrue,
      );
    });
  });

  // ────────────────────────────────────────────────────
  // filteredItems — GoalStatusFilter.completed
  // ────────────────────────────────────────────────────
  group('filteredItems — completed', () {
    test('returns goals with status completed or current >= target', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer(
        (_) async => _result([activeGoal, completedGoal]),
      );
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      await container
          .read(goalsNotifierProvider.notifier)
          .applyUiFilter('Completed');

      final filtered =
          container.read(goalsNotifierProvider.notifier).filteredItems;
      expect(filtered, hasLength(1));
      expect(filtered.first.id, completedGoal.id);
    });
  });

  // ────────────────────────────────────────────────────
  // filteredItems — GoalStatusFilter.canceled
  // ────────────────────────────────────────────────────
  group('filteredItems — canceled', () {
    test('returns only canceled goals', () async {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer(
        (_) async => _result([activeGoal, canceledGoal]),
      );
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      await container
          .read(goalsNotifierProvider.notifier)
          .applyUiFilter('Canceled');

      final filtered =
          container.read(goalsNotifierProvider.notifier).filteredItems;
      expect(filtered, hasLength(1));
      expect(filtered.first.id, canceledGoal.id);
    });
  });

  // ────────────────────────────────────────────────────
  // applyUiFilter()
  // ────────────────────────────────────────────────────
  group('applyUiFilter()', () {
    setUp(() {
      when(() => mockRepo.getGoals(
            status: any(named: 'status'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => _result([]));
    });

    test('changes internal filter to active', () async {
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      await container
          .read(goalsNotifierProvider.notifier)
          .applyUiFilter('Active');

      expect(
        container.read(goalsNotifierProvider.notifier).filter,
        GoalStatusFilter.active,
      );
    });

    test('changes internal filter to completed', () async {
      final container = _makeContainer(
        goalRepo: mockRepo,
        authenticated: true,
      );
      await container.read(goalsNotifierProvider.future);

      await container
          .read(goalsNotifierProvider.notifier)
          .applyUiFilter('Completed');

      expect(
        container.read(goalsNotifierProvider.notifier).filter,
        GoalStatusFilter.completed,
      );
    });
  });

  // ────────────────────────────────────────────────────
  // GoalsViewState model
  // ────────────────────────────────────────────────────
  group('GoalsViewState', () {
    test('copyWith preserves unchanged fields', () {
      final state = GoalsViewState(
        items: [activeGoal],
        fromCache: true,
        isStale: false,
        filter: GoalStatusFilter.all,
      );
      final copy = state.copyWith();
      expect(copy.items, state.items);
      expect(copy.fromCache, state.fromCache);
      expect(copy.filter, state.filter);
    });

    test('copyWith updates filter only', () {
      final state = GoalsViewState(
        items: [],
        fromCache: false,
        isStale: false,
        filter: GoalStatusFilter.all,
      );
      final copy = state.copyWith(filter: GoalStatusFilter.active);
      expect(copy.filter, GoalStatusFilter.active);
      expect(copy.fromCache, false);
    });

    test('copyWith can flip isStale', () {
      final state = GoalsViewState(
        items: [],
        fromCache: false,
        isStale: false,
        filter: GoalStatusFilter.all,
      );
      expect(state.copyWith(isStale: true).isStale, isTrue);
    });

    test('copyWith updates items', () {
      final state = GoalsViewState(
        items: [],
        fromCache: false,
        isStale: false,
        filter: GoalStatusFilter.all,
      );
      final copy = state.copyWith(items: [activeGoal, completedGoal]);
      expect(copy.items, hasLength(2));
    });
  });
}
