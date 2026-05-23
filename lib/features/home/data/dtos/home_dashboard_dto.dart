import 'package:kise/features/home/domain/home_dashboard_models.dart';

class HomeDashboardDto {
  static HomeDashboardBundle fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final balanceJson = json['balance'];
    final allowanceJson = json['allowance'];
    final budgetJson = json['budgetStatus'];
    final trendJson = json['trend'];
    final categoryJson = json['categorySpending'];
    final recentJson = json['recentTransactions'];

    return HomeDashboardBundle(
      user: _parseUser(userJson),
      balance: _parseBalance(balanceJson, userJson),
      allowance: _parseAllowance(allowanceJson),
      budgetStatus: _parseBudgetStatus(budgetJson),
      trend: _parseTrend(trendJson),
      categorySpending: _parseCategorySpending(categoryJson),
      recentTransactions: _parseRecentTransactions(recentJson),
    );
  }

  static HomeDashboardUser _parseUser(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const HomeDashboardUser(
        firstName: '',
        lastName: '',
        email: '',
        currency: 'ETB',
      );
    }

    return HomeDashboardUser(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'ETB',
    );
  }

  static HomeDashboardBalance _parseBalance(
    dynamic json,
    dynamic userJson,
  ) {
    final fallbackCurrency = userJson is Map<String, dynamic>
        ? userJson['currency']?.toString() ?? 'ETB'
        : 'ETB';

    if (json is! Map<String, dynamic>) {
      return HomeDashboardBalance(
        total: 0,
        income: 0,
        expenses: 0,
        currency: fallbackCurrency,
      );
    }

    return HomeDashboardBalance(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      income: (json['income'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? fallbackCurrency,
    );
  }

  static HomeDashboardAllowance _parseAllowance(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const HomeDashboardAllowance(
        monthlyAmount: 0,
        cycleStartDay: 1,
        isConfigured: false,
        cycleSpend: 0,
      );
    }

    return HomeDashboardAllowance(
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0,
      cycleStartDay: (json['cycleStartDay'] as num?)?.toInt() ?? 1,
      isConfigured: json['isConfigured'] == true,
      cycleSpend: (json['cycleSpend'] as num?)?.toDouble() ?? 0,
      cycleFrom: json['cycleFrom']?.toString(),
      cycleTo: json['cycleTo']?.toString(),
    );
  }

  static HomeDashboardBudgetStatus _parseBudgetStatus(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const HomeDashboardBudgetStatus(
        spendRatio: 0,
        personality: 'Getting Started',
        tip: 'Log your first transaction to unlock personalized spending insights.',
      );
    }

    return HomeDashboardBudgetStatus(
      spendRatio: (json['spendRatio'] as num?)?.toDouble() ?? 0,
      personality: json['personality']?.toString() ?? 'Balanced',
      tip: json['tip']?.toString() ?? '',
    );
  }

  static List<HomeTrendPoint> _parseTrend(dynamic json) {
    if (json is! List) {
      return const [];
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => HomeTrendPoint(
            month: item['month']?.toString() ?? '',
            income: (item['income'] as num?)?.toDouble() ?? 0,
            expense: (item['expense'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  static List<HomeCategorySpending> _parseCategorySpending(dynamic json) {
    if (json is! List) {
      return const [];
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => HomeCategorySpending(
            category: item['category']?.toString() ?? 'Other',
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
            percentage: (item['percentage'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  static List<HomeRecentTransaction> _parseRecentTransactions(dynamic json) {
    if (json is! List) {
      return const [];
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => HomeRecentTransaction(
            id: item['id']?.toString() ?? '',
            type: item['type']?.toString() ?? 'Expense',
            title: item['title']?.toString() ?? '',
            category: item['category']?.toString() ?? '',
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
            displayDate: item['displayDate']?.toString(),
            note: item['note']?.toString(),
          ),
        )
        
        .toList(growable: false);
  }
}
