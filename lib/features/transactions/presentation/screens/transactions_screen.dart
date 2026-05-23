import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/kise_action_button.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/widgets/kise_pill_filter.dart';

import '../../domain/transaction_entity.dart';
import '../../domain/transaction_filters.dart';
import '../state/transactions_notifier.dart';
import '../state/transactions_summary_provider.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

String _formatCompactAmount(double value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return value.toStringAsFixed(0);
}

String _formatSavingRate(double rate) {
  return '${(rate * 100).round()}%';
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String selectedFilter = "All";
  String selectedAnalyticsRange = "1 Month";
  int _visibleCount = 3;
  String? _deletingTransactionId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(transactionsNotifierProvider.notifier)
          .applyFilter(const TransactionQueryFilter(limit: 50));
    });
  }

  Future<void> _openEditModal(TransactionEntity transaction) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTransactionModal(transactionToEdit: transaction),
    );
  }

  Future<void> _confirmDelete(TransactionEntity transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'Remove "${transaction.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingTransactionId = transaction.id);

    try {
      await ref
          .read(transactionsNotifierProvider.notifier)
          .deleteTransaction(transaction.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Could not delete transaction. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTransactionId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final summaryAsync = ref.watch(currentMonthSummaryProvider);

    final transactions = transactionsAsync.value ?? const <TransactionEntity>[];

    final totalIncomeLabel = summaryAsync.when(
      data: (summary) => _formatCompactAmount(summary.totalIncome),
      loading: () => '—',
      error: (_, _) => '—',
    );
    final totalSpentLabel = summaryAsync.when(
      data: (summary) => _formatCompactAmount(summary.totalExpense),
      loading: () => '—',
      error: (_, _) => '—',
    );
    final savingRateLabel = summaryAsync.when(
      data: (summary) => _formatSavingRate(summary.savingRate),
      loading: () => '—',
      error: (_, _) => '—',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transactions",
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 24),
                        ),
                        Text(
                          "${transactions.length} records",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    KiseActionButton(
                      label: 'Add',
                      leadingIcon: Icons.add,
                      expanded: false,
                      height: 35,
                      borderRadius: 10,
                      onPressed: () => showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddTransactionModal(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// SEARCH
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search transactions...",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (query) {
                      ref
                          .read(transactionsNotifierProvider.notifier)
                          .updateSearchQuery(query);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// FILTERS
                KisePillFilter(
                  options: const ["All", "Income", "Expense"],
                  selected: selectedFilter,
                  onSelected: (value) {
                    setState(() {
                      selectedFilter = value;
                      _visibleCount = 3;
                    });
                    ref
                        .read(transactionsNotifierProvider.notifier)
                        .updateTypeFilter(value);
                  },
                ),

                const SizedBox(height: 20),

                /// SUMMARY CARDS
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        amount: totalIncomeLabel,
                        label: "Total Income",
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        amount: totalSpentLabel,
                        label: "Total Spent",
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        amount: savingRateLabel,
                        label: "Saving Rate",
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// ANALYTICS TITLE
                Text(
                  "Income vs Expense Analytics",
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 16),

                /// ANALYTICS RANGE FILTER
                KisePillFilter(
                  options: const ["1 Month", "3 Months", "6 Months", "1 Year"],
                  selected: selectedAnalyticsRange,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  onSelected: (value) =>
                      setState(() => selectedAnalyticsRange = value),
                ),

                const SizedBox(height: 20),

                /// ANALYTICS CHART
                KiseCardHolder(
                  child: AnalyticsBarChart(
                    selectedFilter: selectedFilter,
                    selectedRange: selectedAnalyticsRange,
                  ),
                ),

                const SizedBox(height: 28),

                /// TRANSACTIONS CARD
                Builder(
                  builder: (context) {
                    final filtered = selectedFilter == 'All'
                        ? transactions
                        : transactions
                              .where((t) => t.type == selectedFilter)
                              .toList();
                    final visible = filtered.take(_visibleCount).toList();
                    final hasMore = _visibleCount < filtered.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KiseCardHolder(
                          child: Column(
                            children: visible
                                .map(
                                  (t) => TransactionTile(
                                    transaction: t,
                                    onEdit: () => _openEditModal(t),
                                    onDelete: () => _confirmDelete(t),
                                    isDeleting: _deletingTransactionId == t.id,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_visibleCount > 3)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _visibleCount = 3),
                                child: Text(
                                  'Show Less',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (hasMore)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _visibleCount += 3),
                                child: Text(
                                  'Load More',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String amount,
    required String label,
    required Color color,
  }) {
    return KiseCardHolder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
