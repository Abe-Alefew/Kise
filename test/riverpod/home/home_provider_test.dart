// Tests for HomeDashboardBundle model aggregations — covers what the
// planned homeProvider will expose once implemented.
// HomeDashboardNotifier is already tested in home_dashboard_notifier_test.dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:kise/features/home/domain/home_dashboard_models.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

HomeDashboardBundle _bundle({
  double income = 5000,
  double expense = 2000,
  double allowanceSpend = 800,
  double allowanceMonthly = 3000,
  bool allowanceConfigured = true,
  List<HomeTrendPoint> trend = const [],
  List<HomeCategorySpending> categorySpending = const [],
  List<HomeRecentTransaction> recent = const [],
}) =>
    HomeDashboardBundle(
      user: const HomeDashboardUser(
        firstName: 'Abel',
        lastName: 'Bekele',
        email: 'abel@kise.app',
        currency: 'ETB',
      ),
      balance: HomeDashboardBalance(
        total: income - expense,
        income: income,
        expenses: expense,
        currency: 'ETB',
      ),
      allowance: HomeDashboardAllowance(
        monthlyAmount: allowanceMonthly,
        cycleStartDay: 1,
        isConfigured: allowanceConfigured,
        cycleSpend: allowanceSpend,
      ),
      budgetStatus: const HomeDashboardBudgetStatus(
        spendRatio: 0.4,
        personality: 'Saver',
        tip: 'Keep it up!',
      ),
      trend: trend,
      categorySpending: categorySpending,
      recentTransactions: recent,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ────────────────────────────────────────────────────
  // HomeDashboardBalance derived values
  // ────────────────────────────────────────────────────
  group('HomeDashboardBalance', () {
    test('balance = income - expenses', () {
      final bundle = _bundle(income: 5000, expense: 2000);
      expect(bundle.balance.total, 3000.0);
    });

    test('negative balance when expenses exceed income', () {
      final bundle = _bundle(income: 500, expense: 1200);
      expect(bundle.balance.total, -700.0);
    });

    test('zero balance for equal income and expenses', () {
      final bundle = _bundle(income: 1000, expense: 1000);
      expect(bundle.balance.total, 0.0);
    });
  });

  // ────────────────────────────────────────────────────
  // HomeDashboardAllowance cycle progress
  // ────────────────────────────────────────────────────
  group('HomeDashboardAllowance', () {
    test('cycle spend is tracked correctly', () {
      final bundle = _bundle(allowanceSpend: 1200, allowanceMonthly: 3000);
      expect(bundle.allowance.cycleSpend, 1200.0);
      expect(bundle.allowance.monthlyAmount, 3000.0);
    });

    test('unconfigured allowance has isConfigured=false', () {
      final bundle = _bundle(allowanceConfigured: false);
      expect(bundle.allowance.isConfigured, isFalse);
    });

    test('spend ratio (computed externally) is correct', () {
      final a = _bundle(allowanceSpend: 600, allowanceMonthly: 3000).allowance;
      final ratio = a.monthlyAmount > 0
          ? (a.cycleSpend / a.monthlyAmount).clamp(0.0, 1.0)
          : 0.0;
      expect(ratio, closeTo(0.2, 0.001));
    });
  });

  // ────────────────────────────────────────────────────
  // HomeDashboardBudgetStatus
  // ────────────────────────────────────────────────────
  group('HomeDashboardBudgetStatus', () {
    test('spendRatio is stored correctly', () {
      final bundle = _bundle();
      expect(bundle.budgetStatus.spendRatio, 0.4);
    });

    test('personality label is stored', () {
      expect(_bundle().budgetStatus.personality, 'Saver');
    });

    test('tip is non-empty', () {
      expect(_bundle().budgetStatus.tip, isNotEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // HomeTrendPoint
  // ────────────────────────────────────────────────────
  group('HomeTrendPoint', () {
    const trend = [
      HomeTrendPoint(month: 'Jan', income: 5000, expense: 2000),
      HomeTrendPoint(month: 'Feb', income: 4500, expense: 2500),
      HomeTrendPoint(month: 'Mar', income: 6000, expense: 1800),
    ];

    test('trend list stores all points', () {
      final bundle = _bundle(trend: trend);
      expect(bundle.trend, hasLength(3));
    });

    test('income and expense stored per month', () {
      expect(trend[0].income, 5000.0);
      expect(trend[0].expense, 2000.0);
      expect(trend[0].month, 'Jan');
    });

    test('net per month = income - expense', () {
      for (final point in trend) {
        expect(point.income - point.expense, isNonNegative);
      }
    });
  });

  // ────────────────────────────────────────────────────
  // HomeCategorySpending
  // ────────────────────────────────────────────────────
  group('HomeCategorySpending', () {
    const categories = [
      HomeCategorySpending(category: 'Food', amount: 500, percentage: 0.25),
      HomeCategorySpending(category: 'Transport', amount: 300, percentage: 0.15),
      HomeCategorySpending(category: 'Education', amount: 700, percentage: 0.35),
    ];

    test('category spending list is populated', () {
      final bundle = _bundle(categorySpending: categories);
      expect(bundle.categorySpending, hasLength(3));
    });

    test('percentage values are in [0,1] range', () {
      for (final cat in categories) {
        expect(cat.percentage, greaterThanOrEqualTo(0.0));
        expect(cat.percentage, lessThanOrEqualTo(1.0));
      }
    });
  });

  // ────────────────────────────────────────────────────
  // HomeRecentTransaction
  // ────────────────────────────────────────────────────
  group('HomeRecentTransaction', () {
    const txs = [
      HomeRecentTransaction(
          id: '1', type: 'expense', title: 'Coffee', category: 'Food', amount: 45),
      HomeRecentTransaction(
          id: '2', type: 'income', title: 'Salary', category: 'Salary', amount: 5000),
    ];

    test('recent list stores all transactions', () {
      final bundle = _bundle(recent: txs);
      expect(bundle.recentTransactions, hasLength(2));
    });

    test('isExpense is true for expense type', () {
      expect(txs[0].isExpense, isTrue);
    });

    test('isExpense is false for income type', () {
      expect(txs[1].isExpense, isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // HomeDashboardBundle.displayName
  // ────────────────────────────────────────────────────
  group('HomeDashboardBundle.displayName', () {
    test('shows first + last name', () {
      expect(_bundle().displayName, 'Abel Bekele');
    });

    test('falls back to email when names are empty', () {
      final bundle = HomeDashboardBundle(
        user: const HomeDashboardUser(
            firstName: '', lastName: '', email: 'x@x.com', currency: 'ETB'),
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
      expect(bundle.displayName, 'x@x.com');
    });
  });
}
