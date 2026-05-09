import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_card_holder.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction_entity.dart';
import '../../domain/transaction_usecases.dart';

import '../widgets/transaction_tile.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/add_transaction_modal.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {

  late final TransactionUseCases useCases;

  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();

    useCases = TransactionUseCases(
      TransactionRepository(),
    );
  }

  List<TransactionEntity> get filteredTransactions {

    final all =
        useCases.getAllTransactions();

    if (selectedFilter == "All") {
      return all;
    }

    return all.where((transaction) {

      return transaction.type
          == selectedFilter;

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    final totalIncome =
        useCases.calculateTotalIncome();

    final totalExpense =
        useCases.calculateTotalExpense();

    final balance =
        useCases.calculateBalance();

    return Scaffold(

      backgroundColor:
          const Color(0xFFF8F8F8),

      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
      ),

      floatingActionButton:
          FloatingActionButton(

        backgroundColor:
            const Color(0xFFD4AF37),

        onPressed: () {
          showModalBottomSheet(

            context: context,

            isScrollControlled: true,

            backgroundColor: Colors.transparent,

            builder: (context) {

              return const AddTransactionModal();
            },
          );
        },

        child: const Icon(Icons.add),
      ),

      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                /// TOTAL BALANCE CARD
                KiseCardHolder(
                  backgroundColor: const Color(0xFFD4AF37),
                  borderColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Balance", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        "ETB ${balance.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                /// INCOME + EXPENSE ROW
                Row(
                  children: [
                    Expanded(
                      child: KiseCardHolder(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Income", style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 6),
                            Text("ETB ${totalIncome.toStringAsFixed(0)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KiseCardHolder(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Expense", style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 6),
                            Text("ETB ${totalExpense.toStringAsFixed(0)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// FILTER BAR
                TransactionsFilterBar(
                  filters: const ["All", "Income", "Expense"],
                  selectedFilter: selectedFilter,
                  onSelected: (value) => setState(() => selectedFilter = value),
                ),

                const SizedBox(height: 16),

                /// ANALYTICS SECTION
                const KiseCardHolder(
                  child: AnalyticsBarChart(),
                ),

                const SizedBox(height: 20),

                /// TRANSACTIONS HEADER
                const Text("Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

                const SizedBox(height: 12),
              ]),
            ),
          ),

          /// TRANSACTION LIST
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TransactionTile(transaction: filteredTransactions[index]),
                childCount: filteredTransactions.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}