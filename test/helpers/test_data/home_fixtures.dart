// Home-dashboard test fixtures.
// Provides a fully-populated HomeDashboardBundle and individual sub-model
// constants that widget, riverpod, and unit tests can reference directly.

import 'package:kise/features/home/domain/home_dashboard_models.dart';

// ── Sub-models ─────────────────────────────────────────────────────────────────

const testHomeDashboardUser = HomeDashboardUser(
  firstName: 'Abel',
  lastName: 'Bekele',
  email: 'abel@kise.app',
  currency: 'ETB',
);

const testHomeDashboardBalance = HomeDashboardBalance(
  total: 4800.0,
  income: 5000.0,
  expenses: 200.0,
  currency: 'ETB',
);

const testHomeDashboardAllowance = HomeDashboardAllowance(
  monthlyAmount: 3000.0,
  cycleStartDay: 1,
  isConfigured: true,
  cycleSpend: 800.0,
  cycleFrom: '2025-06-01',
  cycleTo: '2025-06-30',
);

const testUnconfiguredAllowance = HomeDashboardAllowance(
  monthlyAmount: 0,
  cycleStartDay: 1,
  isConfigured: false,
  cycleSpend: 0,
);

const testHomeDashboardBudgetStatus = HomeDashboardBudgetStatus(
  spendRatio: 0.27,
  personality: 'Saver',
  tip: 'You are spending well within your allowance. Keep it up!',
);

const testTrend = [
  HomeTrendPoint(month: 'Jan', income: 5000, expense: 2000),
  HomeTrendPoint(month: 'Feb', income: 4800, expense: 2200),
  HomeTrendPoint(month: 'Mar', income: 5200, expense: 1800),
  HomeTrendPoint(month: 'Apr', income: 5000, expense: 2500),
  HomeTrendPoint(month: 'May', income: 5500, expense: 2100),
  HomeTrendPoint(month: 'Jun', income: 5000, expense: 200),
];

const testCategorySpending = [
  HomeCategorySpending(category: 'Food', amount: 80.0, percentage: 0.40),
  HomeCategorySpending(category: 'Transport', amount: 60.0, percentage: 0.30),
  HomeCategorySpending(category: 'Education', amount: 40.0, percentage: 0.20),
  HomeCategorySpending(category: 'Entertainment', amount: 20.0, percentage: 0.10),
];

const testRecentTransactions = [
  HomeRecentTransaction(
    id: 'rt-001',
    type: 'expense',
    title: 'Morning coffee',
    category: 'Food',
    amount: 45.0,
    displayDate: 'Jun 1',
    note: 'Buna',
  ),
  HomeRecentTransaction(
    id: 'rt-002',
    type: 'expense',
    title: 'Bus fare',
    category: 'Transport',
    amount: 15.0,
    displayDate: 'Jun 1',
  ),
  HomeRecentTransaction(
    id: 'rt-003',
    type: 'income',
    title: 'Salary',
    category: 'Salary',
    amount: 5000.0,
    displayDate: 'Jun 1',
  ),
];

// ── Full bundle ────────────────────────────────────────────────────────────────

const testHomeDashboardBundle = HomeDashboardBundle(
  user: testHomeDashboardUser,
  balance: testHomeDashboardBalance,
  allowance: testHomeDashboardAllowance,
  budgetStatus: testHomeDashboardBudgetStatus,
  trend: testTrend,
  categorySpending: testCategorySpending,
  recentTransactions: testRecentTransactions,
);

/// A bundle variant with an unconfigured allowance — tests the "Set allowance"
/// CTA path in AllowanceCard.
const testHomeDashboardBundleNoAllowance = HomeDashboardBundle(
  user: testHomeDashboardUser,
  balance: testHomeDashboardBalance,
  allowance: testUnconfiguredAllowance,
  budgetStatus: testHomeDashboardBudgetStatus,
  trend: testTrend,
  categorySpending: testCategorySpending,
  recentTransactions: testRecentTransactions,
);

/// A bundle with a negative balance — tests the "overspent" colour path in
/// BalanceCard.
const testHomeDashboardBundleNegativeBalance = HomeDashboardBundle(
  user: testHomeDashboardUser,
  balance: HomeDashboardBalance(
    total: -500.0,
    income: 1000.0,
    expenses: 1500.0,
    currency: 'ETB',
  ),
  allowance: testHomeDashboardAllowance,
  budgetStatus: HomeDashboardBudgetStatus(
    spendRatio: 1.0,
    personality: 'Spender',
    tip: 'You have exceeded your allowance this cycle.',
  ),
  trend: testTrend,
  categorySpending: testCategorySpending,
  recentTransactions: testRecentTransactions,
);

/// An empty bundle — tests screens that must show empty-state widgets.
const testHomeDashboardBundleEmpty = HomeDashboardBundle(
  user: testHomeDashboardUser,
  balance: HomeDashboardBalance(
      total: 0, income: 0, expenses: 0, currency: 'ETB'),
  allowance: testUnconfiguredAllowance,
  budgetStatus: HomeDashboardBudgetStatus(
      spendRatio: 0, personality: '', tip: ''),
  trend: [],
  categorySpending: [],
  recentTransactions: [],
);
