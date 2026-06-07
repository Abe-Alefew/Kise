// Tests for transactionAnalyticsProvider (FutureProvider.family) and
// TransactionAnalyticsQuery — range/type mapping, equality, caching.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:kise/features/transactions/presentation/state/transactions_analytics_provider.dart';

import '../../helpers/provider_helper.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockTransactionRepository extends Mock implements TransactionRepository {}

// ── Fixture ───────────────────────────────────────────────────────────────────

TransactionAnalytics _fakeAnalytics() => TransactionAnalytics.fromJson({
      'months': ['Jan', 'Feb', 'Mar'],
      'incomeByMonth': {
        'Jan': {'Salary': 5000},
        'Feb': {'Salary': 5000},
        'Mar': {'Salary': 5000},
      },
      'expenseByMonth': {
        'Jan': {'Food': 500},
        'Feb': {'Food': 400},
        'Mar': {'Food': 600},
      },
      'categoryTotals': {'Food': 1500, 'Transport': 300},
    });

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    when(() => mockRepo.getAnalytics(
          range: any(named: 'range'),
          type: any(named: 'type'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => _fakeAnalytics());
  });

  // ────────────────────────────────────────────────────
  // TransactionAnalyticsQuery.apiRange
  // ────────────────────────────────────────────────────
  group('TransactionAnalyticsQuery.apiRange', () {
    test('"1 Month" maps to "1m"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1 Month').apiRange,
        '1m',
      );
    });

    test('"3 Months" maps to "3m"', () {
      expect(
        const TransactionAnalyticsQuery(range: '3 Months').apiRange,
        '3m',
      );
    });

    test('"6 Months" maps to "6m"', () {
      expect(
        const TransactionAnalyticsQuery(range: '6 Months').apiRange,
        '6m',
      );
    });

    test('"1 Year" maps to "1y"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1 Year').apiRange,
        '1y',
      );
    });

    test('unknown range defaults to "1m"', () {
      expect(
        const TransactionAnalyticsQuery(range: 'custom').apiRange,
        '1m',
      );
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionAnalyticsQuery.apiType
  // ────────────────────────────────────────────────────
  group('TransactionAnalyticsQuery.apiType', () {
    test('"Income" maps to "Income"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1m', type: 'Income').apiType,
        'Income',
      );
    });

    test('"Expense" maps to "Expense"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1m', type: 'Expense').apiType,
        'Expense',
      );
    });

    test('"Expenses" also maps to "Expense"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1m', type: 'Expenses').apiType,
        'Expense',
      );
    });

    test('"All" maps to "all"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1m', type: 'All').apiType,
        'all',
      );
    });

    test('default type is "all"', () {
      expect(
        const TransactionAnalyticsQuery(range: '1m').apiType,
        'all',
      );
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionAnalyticsQuery equality / hashCode
  // ────────────────────────────────────────────────────
  group('TransactionAnalyticsQuery equality', () {
    test('same params → equal', () {
      const q1 = TransactionAnalyticsQuery(range: '3 Months', type: 'Income');
      const q2 = TransactionAnalyticsQuery(range: '3 Months', type: 'Income');
      expect(q1, equals(q2));
      expect(q1.hashCode, q2.hashCode);
    });

    test('different range → not equal', () {
      const q1 = TransactionAnalyticsQuery(range: '1 Month');
      const q2 = TransactionAnalyticsQuery(range: '3 Months');
      expect(q1, isNot(equals(q2)));
    });

    test('different type → not equal', () {
      const q1 = TransactionAnalyticsQuery(range: '1 Month', type: 'Income');
      const q2 = TransactionAnalyticsQuery(range: '1 Month', type: 'Expense');
      expect(q1, isNot(equals(q2)));
    });

    test('forceRefresh=true differs from default', () {
      const q1 = TransactionAnalyticsQuery(range: '1 Month');
      const q2 = TransactionAnalyticsQuery(range: '1 Month', forceRefresh: true);
      expect(q1, isNot(equals(q2)));
    });
  });

  // ────────────────────────────────────────────────────
  // transactionAnalyticsProvider — data loading
  // ────────────────────────────────────────────────────
  group('transactionAnalyticsProvider', () {
    test('fetches analytics and returns data with months', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const query = TransactionAnalyticsQuery(range: '3 Months');
      final analytics =
          await container.read(transactionAnalyticsProvider(query).future);

      expect(analytics.months, hasLength(3));
      expect(analytics.months, containsAll(['Jan', 'Feb', 'Mar']));
    });

    test('passes apiRange to repository', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const query = TransactionAnalyticsQuery(range: '6 Months', type: 'Income');
      await container.read(transactionAnalyticsProvider(query).future);

      verify(() => mockRepo.getAnalytics(
            range: '6m',
            type: 'Income',
            forceRefresh: any(named: 'forceRefresh'),
          )).called(1);
    });

    test('returns categoryTotals as a map', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const query = TransactionAnalyticsQuery(range: '1 Month');
      final analytics =
          await container.read(transactionAnalyticsProvider(query).future);

      expect(analytics.categoryTotals['Food'], 1500.0);
      expect(analytics.categoryTotals['Transport'], 300.0);
    });

    test('two distinct queries create independent provider instances', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const q1 = TransactionAnalyticsQuery(range: '1 Month');
      const q2 = TransactionAnalyticsQuery(range: '3 Months');

      final [a1, a2] = await Future.wait([
        container.read(transactionAnalyticsProvider(q1).future),
        container.read(transactionAnalyticsProvider(q2).future),
      ]);

      expect(a1.months, isNotEmpty);
      expect(a2.months, isNotEmpty);
    });
  });
}
