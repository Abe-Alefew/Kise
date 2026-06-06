import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/home/data/dtos/home_dashboard_dto.dart';

// Fixture builder

Map<String, dynamic> _fullJson({
  Map<String, dynamic>? user,
  Map<String, dynamic>? balance,
  Map<String, dynamic>? allowance,
  Map<String, dynamic>? budgetStatus,
  List<dynamic>? trend,
  List<dynamic>? categorySpending,
  List<dynamic>? recentTransactions,
}) =>
    {
      'user': user ??
          {
            'firstName': 'Abel',
            'lastName': 'Bekele',
            'email': 'abel@kise.app',
            'currency': 'ETB',
          },
      'balance': balance ??
          {
            'total': 4800.0,
            'income': 5000.0,
            'expenses': 200.0,
            'currency': 'ETB',
          },
      'allowance': allowance ??
          {
            'monthlyAmount': 3000.0,
            'cycleStartDay': 1,
            'isConfigured': true,
            'cycleSpend': 800.0,
            'cycleFrom': '2025-06-01',
            'cycleTo': '2025-06-30',
          },
      'budgetStatus': budgetStatus ??
          {
            'spendRatio': 0.27,
            'personality': 'Saver',
            'tip': 'Keep it up!',
          },
      'trend': trend ??
          [
            {'month': 'Jan', 'income': 5000, 'expense': 2000},
            {'month': 'Feb', 'income': 4800, 'expense': 2200},
          ],
      'categorySpending': categorySpending ??
          [
            {'category': 'Food', 'amount': 200, 'percentage': 0.4},
          ],
      'recentTransactions': recentTransactions ??
          [
            {
              'id': 'rt-1',
              'type': 'expense',
              'title': 'Coffee',
              'category': 'Food',
              'amount': 45,
              'displayDate': 'Jun 1',
              'note': 'Morning',
            },
          ],
    };

// 

void main() {
 
  // HomeDashboardDto.fromJson — user section

  group('fromJson — user', () {
    test('parses firstName, lastName, email, currency', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.user.firstName, 'Abel');
      expect(bundle.user.lastName, 'Bekele');
      expect(bundle.user.email, 'abel@kise.app');
      expect(bundle.user.currency, 'ETB');
    });

    test('defaults user fields to empty strings when user is null', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['user'] = null);
      expect(bundle.user.firstName, '');
      expect(bundle.user.email, '');
      expect(bundle.user.currency, 'ETB'); // fallback default
    });

    test('defaults user fields when user is wrong type', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['user'] = 'bad');
      expect(bundle.user.firstName, '');
    });

    test('handles null firstName/lastName inside user object', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(user: {
        'firstName': null,
        'lastName': null,
        'email': 'x@x.com',
        'currency': 'ETB',
      }));
      expect(bundle.user.firstName, '');
      expect(bundle.user.lastName, '');
    });
  });

 
  // balance section

  group('fromJson — balance', () {
    test('parses total, income, expenses, currency', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.balance.total, 4800.0);
      expect(bundle.balance.income, 5000.0);
      expect(bundle.balance.expenses, 200.0);
      expect(bundle.balance.currency, 'ETB');
    });

    test('defaults to zeros when balance is null', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['balance'] = null);
      expect(bundle.balance.total, 0.0);
      expect(bundle.balance.income, 0.0);
    });

    test('falls back to user currency when balance.currency absent', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(balance: {
        'total': 100,
        'income': 200,
        'expenses': 100,
        // no 'currency' key
      }));
      expect(bundle.balance.currency, 'ETB'); // from user.currency
    });

    test('integer amounts are coerced to double', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(balance: {
        'total': 5000,
        'income': 6000,
        'expenses': 1000,
        'currency': 'ETB',
      }));
      expect(bundle.balance.total, 5000.0);
    });
  });


  // allowance section

  group('fromJson — allowance', () {
    test('parses all allowance fields', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.allowance.monthlyAmount, 3000.0);
      expect(bundle.allowance.cycleStartDay, 1);
      expect(bundle.allowance.isConfigured, isTrue);
      expect(bundle.allowance.cycleSpend, 800.0);
      expect(bundle.allowance.cycleFrom, '2025-06-01');
      expect(bundle.allowance.cycleTo, '2025-06-30');
    });

    test('defaults allowance to unconfigured when null', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['allowance'] = null);
      expect(bundle.allowance.isConfigured, isFalse);
      expect(bundle.allowance.monthlyAmount, 0.0);
    });

    test('isConfigured is false when value is not exactly true', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(
          allowance: {'isConfigured': 1, 'monthlyAmount': 3000, 'cycleStartDay': 1, 'cycleSpend': 0}));
      expect(bundle.allowance.isConfigured, isFalse);
    });

    test('cycleFrom and cycleTo are null when absent', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(allowance: {
        'monthlyAmount': 2000,
        'cycleStartDay': 1,
        'isConfigured': true,
        'cycleSpend': 500,
      }));
      expect(bundle.allowance.cycleFrom, isNull);
      expect(bundle.allowance.cycleTo, isNull);
    });
  });


  // budgetStatus section

  group('fromJson — budgetStatus', () {
    test('parses spendRatio, personality, tip', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.budgetStatus.spendRatio, 0.27);
      expect(bundle.budgetStatus.personality, 'Saver');
      expect(bundle.budgetStatus.tip, 'Keep it up!');
    });

    test('defaults to "Getting Started" personality when null', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['budgetStatus'] = null);
      expect(bundle.budgetStatus.personality, 'Getting Started');
      expect(bundle.budgetStatus.spendRatio, 0.0);
    });

    test('defaults personality to "Balanced" when missing from map', () {
      final bundle = HomeDashboardDto.fromJson(
          _fullJson(budgetStatus: {'spendRatio': 0.5, 'tip': 'Good job'}));
      expect(bundle.budgetStatus.personality, 'Balanced');
    });
  });


  // trend section
 
  group('fromJson — trend', () {
    test('parses list of HomeTrendPoint', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.trend, hasLength(2));
      expect(bundle.trend.first.month, 'Jan');
      expect(bundle.trend.first.income, 5000.0);
      expect(bundle.trend.first.expense, 2000.0);
    });

    test('returns empty list when trend is null', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['trend'] = null);
      expect(bundle.trend, isEmpty);
    });

    test('returns empty list when trend is not a List', () {
      final bundle =
          HomeDashboardDto.fromJson(_fullJson()..['trend'] = 'bad');
      expect(bundle.trend, isEmpty);
    });

    test('defaults missing month to empty string', () {
      final bundle = HomeDashboardDto.fromJson(
          _fullJson(trend: [{'income': 1000, 'expense': 500}]));
      expect(bundle.trend.first.month, '');
    });
  });


  // categorySpending section

  group('fromJson — categorySpending', () {
    test('parses category, amount, percentage', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.categorySpending, hasLength(1));
      expect(bundle.categorySpending.first.category, 'Food');
      expect(bundle.categorySpending.first.amount, 200.0);
      expect(bundle.categorySpending.first.percentage, 0.4);
    });

    test('returns empty list when null', () {
      final bundle = HomeDashboardDto.fromJson(
          _fullJson()..['categorySpending'] = null);
      expect(bundle.categorySpending, isEmpty);
    });

    test('defaults category to "Other" when missing', () {
      final bundle = HomeDashboardDto.fromJson(
          _fullJson(categorySpending: [{'amount': 100, 'percentage': 0.1}]));
      expect(bundle.categorySpending.first.category, 'Other');
    });
  });


  // recentTransactions section

  group('fromJson — recentTransactions', () {
    test('parses all transaction fields', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.recentTransactions, hasLength(1));
      final tx = bundle.recentTransactions.first;
      expect(tx.id, 'rt-1');
      expect(tx.type, 'expense');
      expect(tx.title, 'Coffee');
      expect(tx.category, 'Food');
      expect(tx.amount, 45.0);
      expect(tx.displayDate, 'Jun 1');
      expect(tx.note, 'Morning');
    });

    test('returns empty list when null', () {
      final bundle = HomeDashboardDto.fromJson(
          _fullJson()..['recentTransactions'] = null);
      expect(bundle.recentTransactions, isEmpty);
    });

    test('displayDate and note are null when absent from JSON', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(recentTransactions: [
        {'id': '1', 'type': 'income', 'title': 'Salary', 'category': 'Salary', 'amount': 5000},
      ]));
      final tx = bundle.recentTransactions.first;
      expect(tx.displayDate, isNull);
      expect(tx.note, isNull);
    });

    test('defaults type to "Expense" when missing', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(recentTransactions: [
        {'id': '1', 'title': 'X', 'category': 'Y', 'amount': 10},
      ]));
      expect(bundle.recentTransactions.first.type, 'Expense');
    });

    test('isExpense returns true for expense type', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.recentTransactions.first.isExpense, isTrue);
    });

    test('skips non-map entries in the list', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(recentTransactions: [
        {'id': '1', 'type': 'income', 'title': 'X', 'category': 'Y', 'amount': 100},
        'bad',
        42,
      ]));
      expect(bundle.recentTransactions, hasLength(1));
    });
  });
  // displayName (via HomeDashboardBundle)
  group('displayName', () {
    test('returns "firstName lastName" when both present', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson());
      expect(bundle.displayName, 'Abel Bekele');
    });

    test('falls back to email when names are empty', () {
      final bundle = HomeDashboardDto.fromJson(_fullJson(user: {
        'firstName': '',
        'lastName': '',
        'email': 'x@kise.app',
        'currency': 'ETB',
      }));
      expect(bundle.displayName, 'x@kise.app');
    });
  });
}
