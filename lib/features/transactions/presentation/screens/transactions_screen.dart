import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_action_button.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/widgets/kise_pill_filter.dart';

import '../../data/transaction_datasource.dart';

import '../widgets/analytics_bar_chart.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {

  const TransactionsScreen({
    super.key,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {

  String selectedFilter = "All";
  String selectedAnalyticsRange = "1 Month";
  int _visibleCount = 3;

  @override
  Widget build(BuildContext context) {

    final transactions =
        TransactionDatasource.transactions;

    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // floatingActionButton:
      //     FloatingActionButton(

      //   backgroundColor: Theme.of(context).colorScheme.primary,

      //   onPressed: () {

      //     showModalBottomSheet(

      //       context: context,

      //       isScrollControlled: true,

      //       backgroundColor:
      //           Colors.transparent,

      //       builder: (context) {

      //         return const AddTransactionModal();
      //       },
      //     );
      //   },

      //   child: const Icon(Icons.add),
      // ),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(12),

          child: SingleChildScrollView(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// HEADER
                Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    Column(

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          "Transactions",
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
                        ),

                        Text(
                          "${transactions.length} records",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),

                    KiseActionButton(
                      label: 'Add',
                      leadingIcon: Icons.add,
                      expanded: false,
                      height: 35,
                      borderRadius: 10,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddTransactionModal(),
                        );
                      },
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
                        color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
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
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// FILTERS
                KisePillFilter(

                  options: const [
                    "All",
                    "Income",
                    "Expense",
                  ],

                  selected:
                      selectedFilter,

                  onSelected: (value) {
                    setState(() {
                      selectedFilter = value;
                      _visibleCount = 3;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// SUMMARY CARDS
                Row(

                  children: [

                    Expanded(

                      child:
                          _summaryCard(

                        amount: "30.0k",
                        label: "Total Income",
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _summaryCard(
                        amount: "20.0k",
                        label: "Total Spent",
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _summaryCard(
                        amount: "33%",
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 16),

                /// ANALYTICS RANGE FILTER
                KisePillFilter(
                  options: const ["1 Month", "3 Months", "6 Months", "1 Year"],
                  selected: selectedAnalyticsRange,
                  selectedColor: Theme.of(context).colorScheme.secondary,
                  onSelected: (value) => setState(() => selectedAnalyticsRange = value),
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
                Builder(builder: (context) {
                  final filtered = selectedFilter == 'All'
                      ? transactions
                      : transactions.where((t) => t.type == selectedFilter).toList();
                  final visible = filtered.take(_visibleCount).toList();
                  final hasMore = _visibleCount < filtered.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KiseCardHolder(
                        child: Column(
                          children: visible
                              .map((t) => TransactionTile(transaction: t))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_visibleCount > 3)
                            TextButton(
                              onPressed: () => setState(() => _visibleCount = 3),
                              child: Text(
                                'Show Less',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (hasMore)
                            TextButton(
                              onPressed: () => setState(() => _visibleCount += 3),
                              child: Text(
                                'Load More',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                }),

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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

}