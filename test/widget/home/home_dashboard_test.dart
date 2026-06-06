import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/home/data/repositories/home_dashboard_repository.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';
import 'package:kise/features/home/presentation/screens/home_dashboard.dart';

import '../../helpers/test_data/auth_fixtures.dart';
import '../../helpers/widget_helper.dart';

class MockHomeDashboardRepository extends Mock
    implements HomeDashboardRepository {}

class _AuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => authenticatedState;
}

HomeDashboardBundle _fakeBundle() => HomeDashboardBundle(
      user: HomeDashboardUser(
        firstName: testUser.firstName,
        lastName: testUser.lastName,
        email: testUser.email,
        currency: testUser.currency,
      ),
      balance: const HomeDashboardBalance(
          total: 4800, income: 5000, expenses: 200, currency: 'ETB'),
      allowance: const HomeDashboardAllowance(
          monthlyAmount: 3000,
          cycleStartDay: 1,
          isConfigured: true,
          cycleSpend: 500),
      budgetStatus: const HomeDashboardBudgetStatus(
          spendRatio: 0.17, personality: 'Saver', tip: 'Keep it up!'),
      trend: const [],
      categorySpending: const [],
      recentTransactions: const [
        HomeRecentTransaction(
            id: 'r1', type: 'expense', title: 'Coffee', category: 'Food', amount: 45),
      ],
    );

void main() {
  late MockHomeDashboardRepository mockRepo;

  setUp(() {
    mockRepo = MockHomeDashboardRepository();
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.fetchHome(range: any(named: 'range')))
        .thenAnswer((_) async => _fakeBundle());
  });

  group('HomeDashboard', () {
    Widget buildDashboard() => buildWithRouter(
          const HomeDashboard(),
          providerOverrides: [
            homeDashboardRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _AuthNotifier()),
            authStateProvider.overrideWith((ref) => authenticatedState),
          ],
        );

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pump();
      expect(find.byType(HomeDashboard), findsOneWidget);
    });

    testWidgets('shows balance information after loading', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      // BalanceCard shows "TOTAL BALANCE" text
      expect(find.text('TOTAL BALANCE'), findsOneWidget);
    });

    testWidgets('shows recent transactions section', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Recent transactions'), findsOneWidget);
    });

    testWidgets('shows "View all" link for transactions', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('View all'), findsOneWidget);
    });

    testWidgets('shows user name in welcome area', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(
        find.textContaining(testUser.firstName),
        findsAtLeast(1),
      );
    });
  });
}
