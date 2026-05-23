class HomeDashboardBundle {
  final HomeDashboardUser user;
  final HomeDashboardBalance balance;
  final HomeDashboardAllowance allowance;
  final HomeDashboardBudgetStatus budgetStatus;
  final List<HomeTrendPoint> trend;
  final List<HomeCategorySpending> categorySpending;
  final List<HomeRecentTransaction> recentTransactions;

  const HomeDashboardBundle({
    required this.user,
    required this.balance,
    required this.allowance,
    required this.budgetStatus,
    required this.trend,
    required this.categorySpending,
    required this.recentTransactions,
  });

  String get displayName =>
      '${user.firstName} ${user.lastName}'.trim().isEmpty
          ? user.email
          : '${user.firstName} ${user.lastName}'.trim();
}

class HomeDashboardUser {
  final String firstName;
  final String lastName;
  final String email;
  final String currency;

  const HomeDashboardUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.currency,
  });
}

class HomeDashboardBalance {
  final double total;
  final double income;
  final double expenses;
  final String currency;

  const HomeDashboardBalance({
    required this.total,
    required this.income,
    required this.expenses,
    required this.currency,
  });
}

class HomeDashboardAllowance {
  final double monthlyAmount;
  final int cycleStartDay;
  final bool isConfigured;
  final double cycleSpend;
  final String? cycleFrom;
  final String? cycleTo;

  const HomeDashboardAllowance({
    required this.monthlyAmount,
    required this.cycleStartDay,
    required this.isConfigured,
    required this.cycleSpend,
    this.cycleFrom,
    this.cycleTo,
  });
}

class HomeDashboardBudgetStatus {
  final double spendRatio;
  final String personality;
  final String tip;

  const HomeDashboardBudgetStatus({
    required this.spendRatio,
    required this.personality,
    required this.tip,
  });
}

class HomeTrendPoint {
  final String month;
  final double income;
  final double expense;

  const HomeTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class HomeCategorySpending {
  final String category;
  final double amount;
  final double percentage;

  const HomeCategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class HomeRecentTransaction {
  final String id;
  final String type;
  final String title;
  final String category;
  final double amount;
  final String? displayDate;
  final String? note;

  const HomeRecentTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    this.displayDate,
    this.note,
  });

  bool get isExpense => type.toLowerCase() == 'expense';
}
