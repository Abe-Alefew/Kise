import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_action_button.dart';
import '../../../../core/widgets/kise_card_holder.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction_entity.dart';
import '../../domain/transaction_usecases.dart';

import '../widgets/transaction_tile.dart';
import '../widgets/transaction_filter_bar.dart';

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

        onPressed: () {},

        child: const Icon(Icons.add),
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// TOTAL BALANCE CARD
            KiseCardHolder(

              backgroundColor:
                  const Color(0xFFD4AF37),

              borderColor: Colors.transparent,

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Total Balance",

                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(

                    "ETB ${balance.toStringAsFixed(0)}",

                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 28,
                    ),
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

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Income",

                          style: TextStyle(
                            color:
                                Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(

                          "ETB ${totalIncome.toStringAsFixed(0)}",

                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: KiseCardHolder(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Expense",

                          style: TextStyle(
                            color:
                                Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(

                          "ETB ${totalExpense.toStringAsFixed(0)}",

                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// FILTER BAR
            TransactionsFilterBar(

              filters: const [
                "All",
                "Income",
                "Expense",
              ],

              selectedFilter:
                  selectedFilter,

              onSelected: (value) {

                setState(() {
                  selectedFilter = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// TRANSACTION LIST
            Expanded(

              child: ListView.builder(

                itemCount:
                    filteredTransactions.length,

                itemBuilder:
                    (context, index) {

                  return TransactionTile(
                    transaction:
                        filteredTransactions[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}