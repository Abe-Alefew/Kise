import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/presentation/screens/transactions_screen.dart';

import '../../helpers/test_data/transaction_fixtures.dart';
import '../../helpers/widget_helper.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    registerFallbackValue(const TransactionQueryFilter());
    SharedPreferences.setMockInitialValues({});

    when(() => mockRepo.getTransactions(
          filter: any(named: 'filter'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => TransactionListResult(
          items: [incomeTransaction, expenseTransaction],
          fromCache: false,
          isStale: false,
          total: 2,
          hasMore: false,
        ));
    when(() => mockRepo.getSummary(
          from: any(named: 'from'),
          to: any(named: 'to'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => const TransactionSummary(
          totalIncome: 5000,
          totalExpense: 200,
          balance: 4800,
          savingRate: 0.96,
          currency: 'ETB',
        ));
  });

  group('TransactionsScreen', () {
    Widget buildScreen() => buildWithRouter(
          const TransactionsScreen(),
          providerOverrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('shows filter bar after loading', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('All'), findsAtLeast(1));
    });

    testWidgets('shows transaction tiles after data loads', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // Either shows titles or the amount with ETB
      expect(find.textContaining('ETB'), findsAtLeast(1));
    });

    testWidgets('shows "+" for income transactions', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.textContaining('+'), findsAtLeast(1));
    });

    testWidgets('shows "-" for expense transactions', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.textContaining('-'), findsAtLeast(1));
    });
  });
}
