import 'package:kise/features/transactions/data/transaction_icon_mapper.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';

class TransactionDto {
  final String id;
  final String type;
  final String title;
  final String category;
  final double amount;
  final String transactionDate;
  final String displayDate;
  final String month;
  final String? accountId;
  final String? accountName;
  final String? note;
  final String iconKey;

  const TransactionDto({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.transactionDate,
    required this.displayDate,
    required this.month,
    this.accountId,
    this.accountName,
    this.note,
    this.iconKey = 'circle',
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: json['transactionDate'] as String,
      displayDate: json['displayDate'] as String? ??
          TransactionIconMapper.formatDisplayDate(
            DateTime.parse('${json['transactionDate']}T00:00:00.000Z'),
          ),
      month: json['month'] as String? ??
          TransactionIconMapper.formatMonthLabel(
            DateTime.parse('${json['transactionDate']}T00:00:00.000Z'),
          ),
      accountId: json['accountId'] as String?,
      accountName: json['accountName'] as String?,
      note: json['note'] as String?,
      iconKey: json['iconKey'] as String? ??
          TransactionIconMapper.defaultIconKeyForCategory(json['category'] as String),
    );
  }

  factory TransactionDto.fromCacheRow(Map<String, dynamic> row) {
    return TransactionDto(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      amount: (row['amount'] as num).toDouble(),
      transactionDate: row['transaction_date'] as String,
      displayDate: row['display_date'] as String,
      month: row['month_label'] as String,
      accountId: row['account_id'] as String?,
      accountName: row['account_name'] as String?,
      note: row['note'] as String?,
      iconKey: row['icon_key'] as String? ?? 'circle',
    );
  }

  factory TransactionDto.fromCreateInput({
    required String id,
    required String userId,
    required CreateTransactionInput input,
    required DateTime createdAt,
    required bool isDirty,
  }) {
    final parsedDate = DateTime.parse('${input.transactionDate}T00:00:00.000Z');

    return TransactionDto(
      id: id,
      type: input.type,
      title: input.title,
      category: input.category,
      amount: input.amount,
      transactionDate: input.transactionDate,
      displayDate: TransactionIconMapper.formatDisplayDate(parsedDate),
      month: TransactionIconMapper.formatMonthLabel(parsedDate),
      accountId: input.accountId,
      note: input.note,
      iconKey: input.iconKey ??
          TransactionIconMapper.defaultIconKeyForCategory(input.category),
    );
  }

  Map<String, dynamic> toCacheRow({
    required String userId,
    required DateTime syncedAt,
    required bool isDirty,
    bool isDeleted = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'transaction_date': transactionDate,
      'display_date': displayDate,
      'month_label': month,
      'account_id': accountId,
      'account_name': accountName,
      'note': note,
      'icon_key': iconKey,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': syncedAt.toIso8601String(),
      'synced_at': syncedAt.toIso8601String(),
      'created_at': now,
      'updated_at': now,
    };
  }

  TransactionEntity toEntity({bool isDirty = false, String? syncError}) {
    return TransactionEntity(
      id: id,
      title: title,
      category: category,
      amount: amount,
      type: type,
      transactionDate: transactionDate,
      displayDate: displayDate,
      month: month,
      accountId: accountId,
      accountName: accountName,
      note: note,
      iconKey: iconKey,
      isDirty: isDirty,
      syncError: syncError,
    );
  }
}

class TransactionListPageDto {
  final List<TransactionDto> items;
  final int total;
  final bool hasMore;

  const TransactionListPageDto({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  factory TransactionListPageDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final pagination = json['pagination'];

    return TransactionListPageDto(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(TransactionDto.fromJson)
              .toList()
          : <TransactionDto>[],
      total: pagination is Map<String, dynamic>
          ? (pagination['total'] as num?)?.toInt() ?? 0
          : 0,
      hasMore: pagination is Map<String, dynamic>
          ? pagination['hasMore'] == true
          : false,
    );
  }
}

class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double savingRate;
  final String currency;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.savingRate,
    required this.currency,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      savingRate: (json['savingRate'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'ETB',
    );
  }
}

class TransactionAnalytics {
  final List<String> months;
  final Map<String, Map<String, double>> incomeByMonth;
  final Map<String, Map<String, double>> expenseByMonth;
  final Map<String, double> categoryTotals;

  const TransactionAnalytics({
    required this.months,
    required this.incomeByMonth,
    required this.expenseByMonth,
    required this.categoryTotals,
  });

  factory TransactionAnalytics.fromJson(Map<String, dynamic> json) {
    return TransactionAnalytics(
      months: (json['months'] as List?)?.map((e) => e.toString()).toList() ?? [],
      incomeByMonth: _parseNestedMap(json['incomeByMonth']),
      expenseByMonth: _parseNestedMap(json['expenseByMonth']),
      categoryTotals: _parseFlatMap(json['categoryTotals']),
    );
  }

  static Map<String, Map<String, double>> _parseNestedMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    return value.map((key, nested) {
      if (nested is Map) {
        return MapEntry(
          key.toString(),
          nested.map(
            (innerKey, innerValue) => MapEntry(
              innerKey.toString(),
              (innerValue as num?)?.toDouble() ?? 0,
            ),
          ),
        );
      }
      return MapEntry(key.toString(), <String, double>{});
    });
  }

  static Map<String, double> _parseFlatMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    return value.map(
      (key, val) => MapEntry(key.toString(), (val as num?)?.toDouble() ?? 0),
    );
  }
}