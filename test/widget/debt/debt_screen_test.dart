import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/debt/data/dtos/debt_dto.dart';
import 'package:kise/features/debt/data/repositories/debt_repository.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';
import 'package:kise/features/debt/presentation/screens/debt_screen.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

import '../../helpers/test_data/auth_fixtures.dart';
import '../../helpers/test_data/debt_fixtures.dart';
import '../../helpers/widget_helper.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';



class MockDebtRepository extends Mock implements DebtRepository {}

class _AuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => authenticatedState;
}

DebtSummary _emptySummary() => const DebtSummary(
      owedToMe: 0, iOwe: 0, netPosition: 0, recoveryRate: 0,
      counts: {}, totalLent: 0, totalBorrowed: 0,
      outstandingOwedToMe: 0, outstandingIOwe: 0,
    );



void main() {
  late MockDebtRepository mockRepo;

  setUp(() {
    mockRepo = MockDebtRepository();
    registerFallbackValue(DebtListFilter.all);
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.getDebts(
          filter: any(named: 'filter'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async =>
        DebtListResult(items: [], fromCache: false, isStale: false));
    when(() => mockRepo.getSummary(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => _emptySummary());
  });

  group('DebtScreen', () {
    Widget buildDebtScreen({List<DebtEntity> debts = const []}) {
      when(() => mockRepo.getDebts(
            filter: any(named: 'filter'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async =>
          DebtListResult(items: debts, fromCache: false, isStale: false));

      return buildWithRouter(
        const DebtScreen(),
        providerOverrides: [
          debtRepositoryProvider.overrideWithValue(mockRepo),
          authNotifierProvider.overrideWith(() => _AuthNotifier()),
        ],
      );
    }

    group('rendering', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(buildDebtScreen());
        await tester.pump();
        expect(find.byType(DebtScreen), findsOneWidget);
      });

      testWidgets('shows filter pills (All, Active, Lent, Borrowed, Settled)',
          (tester) async {
        await tester.pumpWidget(buildDebtScreen());
        await tester.pumpAndSettle();
        expect(find.text('All'), findsAtLeast(1));
      });
    });

    group('with debts', () {
      testWidgets('shows DebtCard items when debts are loaded', (tester) async {
        await tester.pumpWidget(buildDebtScreen(
          debts: [pendingLentDebt, partialBorrowedDebt],
        ));
        await tester.pumpAndSettle();
        expect(find.byType(StatusBadge), findsWidgets);
      });

      testWidgets('shows person names for loaded debts', (tester) async {
        await tester.pumpWidget(buildDebtScreen(
          debts: [pendingLentDebt],
        ));
        await tester.pumpAndSettle();
        expect(find.text('Bob'), findsOneWidget);
      });
    });
  });
}













































































































































































































