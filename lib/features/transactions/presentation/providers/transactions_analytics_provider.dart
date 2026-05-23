import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/features/transactions/data/transaction_dto.dart';
import 'package:kise/features/transactions/data/transaction_repository.dart';

@immutable
class TransactionAnalyticsQuery {
  final String range;
  final String type;
  final bool forceRefresh;

  const TransactionAnalyticsQuery({
    required this.range,
    this.type = 'all',
    this.forceRefresh = false,
  });

  String get apiRange {
    switch (range) {
      case '1 Month':
        return '1m';
      case '3 Months':
        return '3m';
      case '6 Months':
        return '6m';
      case '1 Year':
        return '1y';
      default:
        return '1m';
    }
  }

  String get apiType {
    switch (type) {
      case 'Income':
        return 'Income';
      case 'Expense':
      case 'Expenses':
        return 'Expense';
      case 'All':
      default:
        return 'all';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionAnalyticsQuery &&
        other.range == range &&
        other.type == type &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(range, type, forceRefresh);
}

final transactionAnalyticsProvider =
    FutureProvider.family<TransactionAnalytics, TransactionAnalyticsQuery>(
  (ref, query) async {
    final repository = ref.watch(transactionRepositoryProvider);

    return repository.getAnalytics(
      range: query.apiRange,
      type: query.apiType,
      forceRefresh: query.forceRefresh,
    );
  },
);

final transactionsScreenAnalyticsProvider =
    Provider.family<AsyncValue<TransactionAnalytics>, TransactionAnalyticsQuery>(
  (ref, query) {
    return ref.watch(transactionAnalyticsProvider(query));
  },
);