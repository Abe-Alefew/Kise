import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/goals/data/repositories/goal_repository.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/presentation/screens/goals_screen.dart';

import '../../helpers/test_data/auth_fixtures.dart';
import '../../helpers/test_data/goal_fixtures.dart';
import '../../helpers/widget_helper.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class _AuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => authenticatedState;
}

void main() {
  late MockGoalRepository mockRepo;

  setUp(() {
    mockRepo = MockGoalRepository();
    registerFallbackValue(GoalStatusFilter.all);
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.getGoals(
          status: any(named: 'status'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async =>
        GoalListResult(items: [activeGoal, completedGoal], fromCache: false, isStale: false));
  });

  group('GoalsScreen', () {
    Widget buildGoalsScreen() => buildWithRouter(
          const GoalsScreen(),
          providerOverrides: [
            goalRepositoryProvider.overrideWithValue(mockRepo),
            authStateProvider.overrideWith((ref) => authenticatedState),
            authNotifierProvider.overrideWith(() => _AuthNotifier()),
          ],
        );

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildGoalsScreen());
      await tester.pump();
      expect(find.byType(GoalsScreen), findsOneWidget);
    });

    testWidgets('shows filter pills', (tester) async {
      await tester.pumpWidget(buildGoalsScreen());
      await tester.pumpAndSettle();
      expect(find.text('All'), findsAtLeast(1));
    });

    testWidgets('shows goal titles after loading', (tester) async {
      await tester.pumpWidget(buildGoalsScreen());
      await tester.pumpAndSettle();
      expect(find.text(activeGoal.title), findsOneWidget);
    });

    testWidgets('shows an add goal button (KiseActionButton)', (tester) async {
      await tester.pumpWidget(buildGoalsScreen());
      await tester.pumpAndSettle();
      // GoalsScreen uses KiseActionButton (ElevatedButton inside) for adding goals
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });
  });
}