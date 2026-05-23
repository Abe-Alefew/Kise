import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/features/transactions/data/dtos/transaction_dto.dart';
import 'package:kise/features/transactions/data/repositories/transaction_repository.dart';

@immutable
class TransactionSummaryQuery {
  final String? from;
  final String? to;
  final bool forceRefresh;

  const TransactionSummaryQuery({
    this.from,
    this.to,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    return other is TransactionSummaryQuery &&
        other.from == from &&
        other.to == to &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(from, to, forceRefresh);
}

final transactionSummaryProvider =
    FutureProvider.family<TransactionSummary, TransactionSummaryQuery>(
  (ref, query) async {
    final repository = ref.watch(transactionRepositoryProvider);

    return repository.getSummary(
      from: query.from,
      to: query.to,
      forceRefresh: query.forceRefresh,
    );
  },
);

final currentMonthSummaryProvider = FutureProvider<TransactionSummary>((ref) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  final to = DateTime(now.year, now.month + 1, 0);

  final fromIso =
      '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
  final toIso =
      '${to.year.toString().padLeft(4, '0')}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getSummary(from: fromIso, to: toIso);
});