import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';

HomeDashboardBundle _makeBundle({
  String firstName = 'Abel',
  String lastName = 'Bekele',
  String email = 'abel@kise.app',
  double balanceTotal = 4800,
  double income = 5000,
  double expenses = 200,
}) {
  return HomeDashboardBundle(
    user: HomeDashboardUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      currency: 'ETB',
    ),
    balance: HomeDashboardBalance(
      total: balanceTotal,
      income: income,
      expenses: expenses,
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
      tip: 'Keep up the good work!',
    ),
    trend: const [
      HomeTrendPoint(month: 'Jan', income: 5000, expense: 2000),
    ],
    categorySpending: const [
      HomeCategorySpending(category: 'Food', amount: 500, percentage: 0.25),
    ],
    recentTransactions: const [
      HomeRecentTransaction(
        id: 'rt-1',
        type: 'expense',
        title: 'Coffee',
        category: 'Food',
        amount: 50,
      ),
    ],
  );
}

void main() {
 
  // HomeDashboardBundle.displayName

  group('HomeDashboardBundle.displayName', () {
    test('returns "firstName lastName" when both are present', () {
      final bundle = _makeBundle(firstName: 'Abel', lastName: 'Bekele');
      expect(bundle.displayName, 'Abel Bekele');
    });

    test('trims when lastName is empty', () {
      final bundle = _makeBundle(firstName: 'Solo', lastName: '');
      expect(bundle.displayName, 'Solo');
    });

    test('trims when firstName is empty', () {
      final bundle = _makeBundle(firstName: '', lastName: 'Bekele');
      expect(bundle.displayName, 'Bekele');
    });

    test('falls back to email when both names are blank', () {
      final bundle =
          _makeBundle(firstName: '', lastName: '', email: 'abel@kise.app');
      expect(bundle.displayName, 'abel@kise.app');
    });

    test('falls back to email when both names are whitespace', () {
      final bundle =
          _makeBundle(firstName: '  ', lastName: '  ', email: 'u@x.com');
      expect(bundle.displayName, 'u@x.com');
    });
  });


  // HomeDashboardBalance

  group('HomeDashboardBalance', () {
    test('stores income, expenses, and total', () {
      const balance = HomeDashboardBalance(
        total: 4800,
        income: 5000,
        expenses: 200,
        currency: 'ETB',
      );
      expect(balance.total, 4800.0);
      expect(balance.income, 5000.0);
      expect(balance.expenses, 200.0);
      expect(balance.currency, 'ETB');
    });

    test('total can be negative (overspent)', () {
      const balance = HomeDashboardBalance(
        total: -200,
        income: 800,
        expenses: 1000,
        currency: 'ETB',
      );
      expect(balance.total, -200.0);
    });
  });

  // HomeDashboardAllowance

  group('HomeDashboardAllowance', () {
    test('stores all required fields', () {
      const allowance = HomeDashboardAllowance(
        monthlyAmount: 3000,
        cycleStartDay: 5,
        isConfigured: true,
        cycleSpend: 1200,
        cycleFrom: '2025-06-05',
        cycleTo: '2025-07-04',
      );
      expect(allowance.monthlyAmount, 3000.0);
      expect(allowance.cycleStartDay, 5);
      expect(allowance.isConfigured, isTrue);
      expect(allowance.cycleSpend, 1200.0);
      expect(allowance.cycleFrom, '2025-06-05');
      expect(allowance.cycleTo, '2025-07-04');
    });

    test('cycleFrom and cycleTo are nullable', () {
      const allowance = HomeDashboardAllowance(
        monthlyAmount: 0,
        cycleStartDay: 1,
        isConfigured: false,
        cycleSpend: 0,
      );
      expect(allowance.cycleFrom, isNull);
      expect(allowance.cycleTo, isNull);
    });
  });


  // HomeDashboardBudgetStatus
 
  group('HomeDashboardBudgetStatus', () {
    test('stores spendRatio, personality, tip', () {
      const status = HomeDashboardBudgetStatus(
        spendRatio: 0.85,
        personality: 'Spender',
        tip: 'Try to reduce food expenses.',
      );
      expect(status.spendRatio, 0.85);
      expect(status.personality, 'Spender');
      expect(status.tip, 'Try to reduce food expenses.');
    });
  });

  // HomeTrendPoint

  group('HomeTrendPoint', () {
    test('stores month, income, expense', () {
      const point = HomeTrendPoint(month: 'Jun', income: 5000, expense: 2000);
      expect(point.month, 'Jun');
      expect(point.income, 5000.0);
      expect(point.expense, 2000.0);
    });
  });

 
  // HomeCategorySpending
 
  group('HomeCategorySpending', () {
    test('stores category, amount, percentage', () {
      const spending = HomeCategorySpending(
        category: 'Transport',
        amount: 400,
        percentage: 0.20,
      );
      expect(spending.category, 'Transport');
      expect(spending.amount, 400.0);
      expect(spending.percentage, 0.20);
    });
  });

  // HomeRecentTransaction

  group('HomeRecentTransaction', () {
    test('isExpense returns true for lowercase "expense"', () {
      const tx = HomeRecentTransaction(
        id: 'r1',
        type: 'expense',
        title: 'Coffee',
        category: 'Food',
        amount: 50,
      );
      expect(tx.isExpense, isTrue);
    });

    test('isExpense returns true for uppercase "EXPENSE" (case-insensitive)', () {
      const tx = HomeRecentTransaction(
        id: 'r2',
        type: 'EXPENSE',
        title: 'Bus fare',
        category: 'Transport',
        amount: 10,
      );
      expect(tx.isExpense, isTrue);
    });

    test('isExpense returns false for income type', () {
      const tx = HomeRecentTransaction(
        id: 'r3',
        type: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 5000,
      );
      expect(tx.isExpense, isFalse);
    });

    test('displayDate and note are nullable', () {
      const tx = HomeRecentTransaction(
        id: 'r4',
        type: 'expense',
        title: 'Misc',
        category: 'Other',
        amount: 30,
      );
      expect(tx.displayDate, isNull);
      expect(tx.note, isNull);
    });
  });
}
