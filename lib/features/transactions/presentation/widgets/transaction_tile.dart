import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_card_holder.dart';
import '../../domain/transaction_entity.dart';

class TransactionTile extends StatelessWidget {

  final TransactionEntity transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {

    final bool isIncome =
        transaction.type == "Income";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

        child: Row(

          children: [

            /// ICON
            Container(

              width: 50,
              height: 50,

              decoration: BoxDecoration(

                color:
                    isIncome
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),

                shape: BoxShape.circle,
              ),

              child: Center(
                child: Text(
                  transaction.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(width: 14),

            /// TITLE + CATEGORY
            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    transaction.title,

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${transaction.category} • ${transaction.date}",

                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            /// AMOUNT
            Text(

              "${isIncome ? "+" : "-"}${transaction.amount} ETB",

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,

                color:
                    isIncome
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
    );
  }
}