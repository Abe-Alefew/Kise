// Tests for transactionSummaryProvider (FutureProvider.family) and
// currentMonthSummaryProvider — both delegate to TransactionRepository.getSummary().

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:kise/features/transactions/presentation/state/transactions_summary_provider.dart';

import '../../helpers/provider_helper.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockTransactionRepository extends Mock implements TransactionRepository {}

// ── Fixture ───────────────────────────────────────────────────────────────────

TransactionSummary _fakeSummary({
  double income = 5000,
  double expense = 2000,
}) =>
    TransactionSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      savingRate: expense > 0 ? 1 - (expense / income) : 1,
      currency: 'ETB',
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    when(() => mockRepo.getSummary(
          from: any(named: 'from'),
          to: any(named: 'to'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => _fakeSummary());
  });

  // ────────────────────────────────────────────────────
  // transactionSummaryProvider (FutureProvider.family)
  // ────────────────────────────────────────────────────
  group('transactionSummaryProvider', () {
    test('fetches summary for a custom date range', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const query = TransactionSummaryQuery(
        from: '2025-01-01',
        to: '2025-06-30',
      );
      final summary = await container.read(
        transactionSummaryProvider(query).future,
      );

      expect(summary.totalIncome, 5000.0);
      expect(summary.totalExpense, 2000.0);
      expect(summary.balance, 3000.0);
      expect(summary.currency, 'ETB');
    });

    test('calls repository with correct from/to dates', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const query =
          TransactionSummaryQuery(from: '2025-01-01', to: '2025-03-31');
      await container.read(transactionSummaryProvider(query).future);

      verify(() => mockRepo.getSummary(
            from: '2025-01-01',
            to: '2025-03-31',
            forceRefresh: any(named: 'forceRefresh'),
          )).called(1);
    });

    test('two different queries produce separate provider instances', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      const q1 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-03-31');
      const q2 = TransactionSummaryQuery(from: '2025-04-01', to: '2025-06-30');

      final [s1, s2] = await Future.wait([
        container.read(transactionSummaryProvider(q1).future),
        container.read(transactionSummaryProvider(q2).future),
      ]);

      expect(s1.currency, 'ETB');
      expect(s2.currency, 'ETB');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionSummaryQuery equality
  // ────────────────────────────────────────────────────
  group('TransactionSummaryQuery equality', () {
    test('two queries with same params are equal', () {
      const q1 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-06-30');
      const q2 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-06-30');
      expect(q1, equals(q2));
    });

    test('two queries with different dates are not equal', () {
      const q1 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-03-31');
      const q2 = TransactionSummaryQuery(from: '2025-04-01', to: '2025-06-30');
      expect(q1, isNot(equals(q2)));
    });

    test('hashCode is stable across equal instances', () {
      const q1 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-06-30');
      const q2 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-06-30');
      expect(q1.hashCode, q2.hashCode);
    });

    test('forceRefresh=true differs from default', () {
      const q1 = TransactionSummaryQuery(from: '2025-01-01', to: '2025-06-30');
      const q2 = TransactionSummaryQuery(
          from: '2025-01-01', to: '2025-06-30', forceRefresh: true);
      expect(q1, isNot(equals(q2)));
    });
  });

  // ────────────────────────────────────────────────────
  // currentMonthSummaryProvider
  // ────────────────────────────────────────────────────
  group('currentMonthSummaryProvider', () {
    test('fetches summary with current month date range', () async {
      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final summary =
          await container.read(currentMonthSummaryProvider.future);
      expect(summary.totalIncome, 5000.0);
      expect(summary.totalExpense, 2000.0);
    });

    test('passes from= first day of current month', () async {
      final now = DateTime.now();
      final expectedFrom =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';

      final container = createContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(currentMonthSummaryProvider.future);

      verify(() => mockRepo.getSummary(
            from: expectedFrom,
            to: any(named: 'to'),
            forceRefresh: any(named: 'forceRefresh'),
          )).called(1);
    });
  });
}
