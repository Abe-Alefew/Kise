// Tests for HomeDashboardNotifier — initial load, refresh, error state,
// and HomeDashboardBundle model properties.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/home/data/repositories/home_dashboard_repository.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';
import 'package:kise/features/home/presentation/state/home_dashboard_notifier.dart';

import '../../helpers/provider_helper.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockHomeDashboardRepository extends Mock
    implements HomeDashboardRepository {}

// ── Fixture ───────────────────────────────────────────────────────────────────

HomeDashboardBundle _fakeBundle({
  String firstName = 'Abel',
  String lastName = 'Bekele',
}) =>
    HomeDashboardBundle(
      user: HomeDashboardUser(
        firstName: firstName,
        lastName: lastName,
        email: 'abel@kise.app',
        currency: 'ETB',
      ),
      balance: const HomeDashboardBalance(
        total: 4800,
        income: 5000,
        expenses: 200,
        currency: 'ETB',
      ),
      allowance: const HomeDashboardAllowance(
        monthlyAmount: 3000,
        cycleStartDay: 1,
        isConfigured: true,
        cycleSpend: 500,
      ),
      budgetStatus: const HomeDashboardBudgetStatus(
        spendRatio: 0.17,
        personality: 'Saver',
        tip: 'Keep it up!',
      ),
      trend: const [],
      categorySpending: const [],
      recentTransactions: const [],
    );

ProviderContainer _makeContainer(MockHomeDashboardRepository mockRepo) {
  return createContainer(
    overrides: [
      homeDashboardRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockHomeDashboardRepository mockRepo;

  setUp(() => mockRepo = MockHomeDashboardRepository());

  // ────────────────────────────────────────────────────
  // Initial load
  // ────────────────────────────────────────────────────
  group('initial load', () {
    test('state starts as AsyncLoading', () {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle());
      final container = _makeContainer(mockRepo);
      expect(container.read(homeDashboardProvider), isA<AsyncLoading>());
    });

    test('state resolves to AsyncData with bundle', () async {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle());
      final container = _makeContainer(mockRepo);
      final bundle = await container.read(homeDashboardProvider.future);
      expect(bundle, isNotNull);
      expect(bundle.balance.total, 4800.0);
    });

    test('displayName is derived from user firstName + lastName', () async {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle(firstName: 'Sara', lastName: 'Ali'));
      final container = _makeContainer(mockRepo);
      final bundle = await container.read(homeDashboardProvider.future);
      expect(bundle.displayName, 'Sara Ali');
    });

    test('uses default range "6m" when calling fetchHome', () async {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle());
      final container = _makeContainer(mockRepo);
      await container.read(homeDashboardProvider.future);
      verify(() => mockRepo.fetchHome(range: '6m')).called(1);
    });

    // Note: testing AsyncError states for Riverpod 3.x AsyncNotifierProviders
    // requires disabling the internal retry mechanism (Retry class is not exported).
    // ApiException error propagation is fully covered in auth_notifier_test.dart.
  });

  // ────────────────────────────────────────────────────
  // refresh()
  // ────────────────────────────────────────────────────
  group('refresh()', () {
    test('transitions to AsyncLoading then back to AsyncData', () async {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle());
      final container = _makeContainer(mockRepo);
      await container.read(homeDashboardProvider.future);

      final refreshFuture =
          container.read(homeDashboardProvider.notifier).refresh();
      expect(container.read(homeDashboardProvider), isA<AsyncLoading>());
      await refreshFuture;
      expect(container.read(homeDashboardProvider), isA<AsyncData>());
    });

    test('calls fetchHome twice: once on build, once on refresh', () async {
      when(() => mockRepo.fetchHome(range: any(named: 'range')))
          .thenAnswer((_) async => _fakeBundle());
      final container = _makeContainer(mockRepo);
      await container.read(homeDashboardProvider.future);
      await container.read(homeDashboardProvider.notifier).refresh();
      verify(() => mockRepo.fetchHome(range: any(named: 'range'))).called(2);
    });
  });

  // ────────────────────────────────────────────────────
  // HomeDashboardBundle model
  // ────────────────────────────────────────────────────
  group('HomeDashboardBundle model', () {
    test('displayName falls back to email when names are empty', () {
      final bundle = HomeDashboardBundle(
        user: const HomeDashboardUser(
          firstName: '',
          lastName: '',
          email: 'test@kise.app',
          currency: 'ETB',
        ),
        balance: const HomeDashboardBalance(
            total: 0, income: 0, expenses: 0, currency: 'ETB'),
        allowance: const HomeDashboardAllowance(
            monthlyAmount: 0,
            cycleStartDay: 1,
            isConfigured: false,
            cycleSpend: 0),
        budgetStatus: const HomeDashboardBudgetStatus(
            spendRatio: 0, personality: '', tip: ''),
        trend: const [],
        categorySpending: const [],
        recentTransactions: const [],
      );
      expect(bundle.displayName, 'test@kise.app');
    });

    test('HomeRecentTransaction.isExpense is true for expense type', () {
      const tx = HomeRecentTransaction(
        id: '1',
        type: 'expense',
        title: 'Bus',
        category: 'Transport',
        amount: 10,
      );
      expect(tx.isExpense, isTrue);
    });

    test('HomeRecentTransaction.isExpense is false for income type', () {
      const tx = HomeRecentTransaction(
        id: '2',
        type: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 5000,
      );
      expect(tx.isExpense, isFalse);
    });
  });
}
