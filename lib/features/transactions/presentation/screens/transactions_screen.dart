import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
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

  String selectedAnalyticsRange =
      "1 Month";

  @override
  Widget build(BuildContext context) {

    final transactions =
        TransactionDatasource.transactions;

    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      floatingActionButton:
          FloatingActionButton(

        backgroundColor: AppColorsLight.primary,

        onPressed: () {

          showModalBottomSheet(

            context: context,

            isScrollControlled: true,

            backgroundColor:
                Colors.transparent,

            builder: (context) {

              return const AddTransactionModal();
            },
          );
        },

        child: const Icon(Icons.add),
      ),

      body: SafeArea(

        child: Padding(

          padding:
              const EdgeInsets.all(16),

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

                        const Text(

                          "Transactions",

                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColorsLight.textHeading,
                          ),
                        ),

                        Text(

                          "${transactions.length} records",

                          style: const TextStyle(
                            color: AppColorsLight.textBody,
                          ),
                        ),
                      ],
                    ),

                    ElevatedButton.icon(

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor: AppColorsLight.primary,

                        foregroundColor: AppColorsLight.textOnPrimary,

                        minimumSize: Size.zero,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),

                      onPressed: () {

                        showModalBottomSheet(

                          context: context,

                          isScrollControlled:
                              true,

                          backgroundColor:
                              Colors.transparent,

                          builder: (context) {

                            return const AddTransactionModal();
                          },
                        );
                      },

                      icon: const Icon(Icons.add),

                      label: const Text("Add"),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// SEARCH
                TextField(

                  decoration: InputDecoration(

                    hintText: "Search transactions...",

                    prefixIcon: const Icon(Icons.search),

                    filled: true,

                    fillColor: Theme.of(context).colorScheme.surface,

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                              14),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// FILTERS
                KisePillFilter(

                  options: const [
                    "All",
                    "Income",
                    "Expenses",
                  ],

                  selected:
                      selectedFilter,

                  onSelected: (value) {

                    setState(() {

                      selectedFilter =
                          value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// SUMMARY CARDS
                Row(

                  children: [

                    Expanded(

                      child:
                          _summaryCard(

                        amount: "30.0k",

                        label:
                            "Total Income",

                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child:
                          _summaryCard(

                        amount: "20.0k",

                        label:
                            "Total Spent",

                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child:
                          _summaryCard(

                        amount: "33%",

                        label:
                            "Saving Rate",

                        color:
                            const Color(
                                0xFF22C55E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                /// ANALYTICS TITLE
                const Text(

                  "Income vs Expense Analytics",

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColorsLight.textHeading,
                  ),
                ),

                const SizedBox(height: 18),

                /// ANALYTICS RANGE FILTER
                SingleChildScrollView(

                  scrollDirection:
                      Axis.horizontal,

                  child: Row(

                    children: [

                      _analyticsFilter(
                          "1 Month"),

                      _analyticsFilter(
                          "3 Months"),

                      _analyticsFilter(
                          "6 Months"),

                      _analyticsFilter(
                          "1 Year"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ANALYTICS CHART
                KiseCardHolder(

                  child: AnalyticsBarChart(

                    selectedFilter:
                        selectedFilter,
                  ),
                ),

                const SizedBox(height: 24),

                /// TRANSACTIONS CARD
                KiseCardHolder(

                  child: Column(

                    children:

                        transactions.map((transaction) {

                      return TransactionTile(
                        transaction:
                            transaction,
                      );

                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                /// LOAD MORE
                Center(

                  child: TextButton(

                    onPressed: () {},

                    child: const Text(
                      "Load More Transactions",
                      style: TextStyle(
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
      ),

      child: Column(

        children: [

          Text(

            amount,

            style: TextStyle(

              color: color,

              fontSize: 24,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: TextStyle(
              color: AppColorsLight.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsFilter(String label) {

    final isSelected =
        selectedAnalyticsRange == label;

    return Padding(

      padding:
          const EdgeInsets.only(
              right: 10),

      child: GestureDetector(

        onTap: () {

          setState(() {

            selectedAnalyticsRange =
                label;
          });
        },

        child: Container(

          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          decoration: BoxDecoration(

            color: isSelected ? const Color(0xFFF3E8C8) : Theme.of(context).colorScheme.surface,

            borderRadius:
                BorderRadius.circular(
                    20),
          ),

          child: Text(

            label,

            style: TextStyle(

              color: isSelected ? AppColorsLight.primary : AppColorsLight.textHint,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}