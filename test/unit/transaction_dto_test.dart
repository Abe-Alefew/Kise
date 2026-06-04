import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';

// ── shared valid JSON fixture ─────────────────────────────────────────────────
Map<String, dynamic> _validJson({
  String? displayDate,
  String? month,
  String? iconKey,
}) =>
    {
      'id': 'tx-dto-001',
      'type': 'expense',
      'title': 'Coffee',
      'category': 'Food',
      'amount': 45.0,
      'transactionDate': '2025-06-01',
      if (displayDate != null) 'displayDate': displayDate,
      if (month != null) 'month': month,
      if (iconKey != null) 'iconKey': iconKey,
    };

void main() {
  // ────────────────────────────────────────────────────
  // TransactionDto.fromJson
  // ────────────────────────────────────────────────────
  group('TransactionDto.fromJson', () {
    test('parses all required fields', () {
      final dto = TransactionDto.fromJson(_validJson(
        displayDate: 'Jun 1',
        month: 'Jun',
        iconKey: 'shoppingCart',
      ));
      expect(dto.id, 'tx-dto-001');
      expect(dto.type, 'expense');
      expect(dto.title, 'Coffee');
      expect(dto.category, 'Food');
      expect(dto.amount, 45.0);
      expect(dto.transactionDate, '2025-06-01');
    });

    test('uses provided displayDate and month', () {
      final dto = TransactionDto.fromJson(_validJson(
        displayDate: 'Jun 1',
        month: 'Jun',
      ));
      expect(dto.displayDate, 'Jun 1');
      expect(dto.month, 'Jun');
    });

    test('computes displayDate from transactionDate when absent', () {
      final dto = TransactionDto.fromJson(_validJson());
      // 2025-06-01 → "Jun 1"
      expect(dto.displayDate, 'Jun 1');
    });

    test('computes month from transactionDate when absent', () {
      final dto = TransactionDto.fromJson(_validJson());
      expect(dto.month, 'Jun');
    });

    test('uses provided iconKey', () {
      final dto = TransactionDto.fromJson(_validJson(iconKey: 'gift'));
      expect(dto.iconKey, 'gift');
    });

    test('derives iconKey from category when absent', () {
      final dto = TransactionDto.fromJson(_validJson());
      // 'Food' → 'shoppingCart'
      expect(dto.iconKey, 'shoppingCart');
    });

    test('optional accountId defaults to null', () {
      expect(TransactionDto.fromJson(_validJson()).accountId, isNull);
    });

    test('optional note defaults to null', () {
      expect(TransactionDto.fromJson(_validJson()).note, isNull);
    });

    test('parses accountId and accountName when provided', () {
      final json = _validJson()
        ..['accountId'] = 'acc-123'
        ..['accountName'] = 'CBE';
      final dto = TransactionDto.fromJson(json);
      expect(dto.accountId, 'acc-123');
      expect(dto.accountName, 'CBE');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionDto.fromCacheRow
  // ────────────────────────────────────────────────────
  group('TransactionDto.fromCacheRow', () {
    final row = {
      'id': 'tx-cache-001',
      'type': 'income',
      'title': 'Salary',
      'category': 'Salary',
      'amount': 5000.0,
      'transaction_date': '2025-06-01',
      'display_date': 'Jun 1',
      'month_label': 'Jun',
      'account_id': null,
      'account_name': null,
      'note': null,
      'icon_key': 'briefcase',
    };

    test('maps snake_case cache columns to camelCase fields', () {
      final dto = TransactionDto.fromCacheRow(row);
      expect(dto.id, 'tx-cache-001');
      expect(dto.type, 'income');
      expect(dto.transactionDate, '2025-06-01');
      expect(dto.displayDate, 'Jun 1');
      expect(dto.month, 'Jun');
      expect(dto.iconKey, 'briefcase');
    });

    test('defaults iconKey to "circle" when cache row has null', () {
      final nullIconRow = Map<String, dynamic>.from(row)..['icon_key'] = null;
      final dto = TransactionDto.fromCacheRow(nullIconRow);
      expect(dto.iconKey, 'circle');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionDto.toEntity
  // ────────────────────────────────────────────────────
  group('TransactionDto.toEntity', () {
    test('converts to TransactionEntity correctly', () {
      final dto = TransactionDto.fromJson(_validJson(
        displayDate: 'Jun 1',
        month: 'Jun',
        iconKey: 'shoppingCart',
      ));
      final entity = dto.toEntity();
      expect(entity.id, dto.id);
      expect(entity.title, dto.title);
      expect(entity.category, dto.category);
      expect(entity.amount, dto.amount);
      expect(entity.type, dto.type);
      expect(entity.isDirty, isFalse);
    });

    test('propagates isDirty flag to entity', () {
      final dto = TransactionDto.fromJson(_validJson(displayDate: 'Jun 1', month: 'Jun'));
      final entity = dto.toEntity(isDirty: true);
      expect(entity.isDirty, isTrue);
    });

    test('propagates syncError to entity', () {
      final dto = TransactionDto.fromJson(_validJson(displayDate: 'Jun 1', month: 'Jun'));
      final entity = dto.toEntity(syncError: 'network error');
      expect(entity.syncError, 'network error');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionDto.toCacheRow
  // ────────────────────────────────────────────────────
  group('TransactionDto.toCacheRow', () {
    test('includes required cache columns', () {
      final dto = TransactionDto.fromJson(_validJson(displayDate: 'Jun 1', month: 'Jun', iconKey: 'shoppingCart'));
      final syncedAt = DateTime(2025, 6, 1);
      final row = dto.toCacheRow(
        userId: 'user-001',
        syncedAt: syncedAt,
        isDirty: false,
      );
      expect(row['id'], 'tx-dto-001');
      expect(row['user_id'], 'user-001');
      expect(row['type'], 'expense');
      expect(row['title'], 'Coffee');
      expect(row['amount'], 45.0);
      expect(row['is_dirty'], 0);
      expect(row['is_deleted'], 0);
    });

    test('marks is_dirty as 1 when isDirty=true', () {
      final dto = TransactionDto.fromJson(_validJson(displayDate: 'Jun 1', month: 'Jun'));
      final row = dto.toCacheRow(
        userId: 'u',
        syncedAt: DateTime.now(),
        isDirty: true,
      );
      expect(row['is_dirty'], 1);
    });

    test('marks is_deleted as 1 when isDeleted=true', () {
      final dto = TransactionDto.fromJson(_validJson(displayDate: 'Jun 1', month: 'Jun'));
      final row = dto.toCacheRow(
        userId: 'u',
        syncedAt: DateTime.now(),
        isDirty: false,
        isDeleted: true,
      );
      expect(row['is_deleted'], 1);
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionListPageDto.fromJson
  // ────────────────────────────────────────────────────
  group('TransactionListPageDto.fromJson', () {
    test('parses items list and pagination', () {
      final json = {
        'items': [
          {
            'id': 'tx-1',
            'type': 'expense',
            'title': 'Bus',
            'category': 'Transport',
            'amount': 10.0,
            'transactionDate': '2025-06-01',
          }
        ],
        'pagination': {
          'total': 50,
          'hasMore': true,
        },
      };
      final page = TransactionListPageDto.fromJson(json);
      expect(page.items, hasLength(1));
      expect(page.total, 50);
      expect(page.hasMore, isTrue);
    });

    test('returns empty items when items is absent', () {
      final json = {'items': null, 'pagination': {'total': 0, 'hasMore': false}};
      final page = TransactionListPageDto.fromJson(json);
      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });

    test('defaults total to 0 when pagination absent', () {
      final page = TransactionListPageDto.fromJson({'items': []});
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionSummary.fromJson
  // ────────────────────────────────────────────────────
  group('TransactionSummary.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'totalIncome': 10000,
        'totalExpense': 4000,
        'balance': 6000,
        'savingRate': 0.6,
        'currency': 'ETB',
      };
      final summary = TransactionSummary.fromJson(json);
      expect(summary.totalIncome, 10000.0);
      expect(summary.totalExpense, 4000.0);
      expect(summary.balance, 6000.0);
      expect(summary.savingRate, 0.6);
      expect(summary.currency, 'ETB');
    });

    test('defaults to 0 for missing numeric fields', () {
      final summary = TransactionSummary.fromJson({});
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.balance, 0.0);
      expect(summary.savingRate, 0.0);
    });

    test('defaults currency to "ETB"', () {
      final summary = TransactionSummary.fromJson({});
      expect(summary.currency, 'ETB');
    });

    test('balance can be negative', () {
      final summary = TransactionSummary.fromJson({
        'totalIncome': 500,
        'totalExpense': 1000,
        'balance': -500,
        'savingRate': 0,
        'currency': 'ETB',
      });
      expect(summary.balance, -500.0);
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionAnalytics.fromJson
  // ────────────────────────────────────────────────────
  group('TransactionAnalytics.fromJson', () {
    test('parses months list', () {
      final analytics = TransactionAnalytics.fromJson({
        'months': ['Jan', 'Feb', 'Mar'],
        'incomeByMonth': {},
        'expenseByMonth': {},
        'categoryTotals': {},
      });
      expect(analytics.months, ['Jan', 'Feb', 'Mar']);
    });

    test('parses categoryTotals as flat double map', () {
      final analytics = TransactionAnalytics.fromJson({
        'months': [],
        'incomeByMonth': {},
        'expenseByMonth': {},
        'categoryTotals': {'Food': 500, 'Transport': 200},
      });
      expect(analytics.categoryTotals['Food'], 500.0);
      expect(analytics.categoryTotals['Transport'], 200.0);
    });

    test('parses incomeByMonth as nested map', () {
      final analytics = TransactionAnalytics.fromJson({
        'months': ['Jun'],
        'incomeByMonth': {
          'Jun': {'Salary': 5000}
        },
        'expenseByMonth': {},
        'categoryTotals': {},
      });
      expect(analytics.incomeByMonth['Jun']?['Salary'], 5000.0);
    });

    test('returns empty maps for missing fields', () {
      final analytics = TransactionAnalytics.fromJson({});
      expect(analytics.months, isEmpty);
      expect(analytics.categoryTotals, isEmpty);
      expect(analytics.incomeByMonth, isEmpty);
      expect(analytics.expenseByMonth, isEmpty);
    });

    test('handles non-map categoryTotals gracefully', () {
      final analytics = TransactionAnalytics.fromJson({
        'categoryTotals': 'not a map',
      });
      expect(analytics.categoryTotals, isEmpty);
    });
  });
}
