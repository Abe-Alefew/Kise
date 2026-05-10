import 'package:flutter/material.dart';

import '../../domain/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == "Income";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        children: [
          /// ICON
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: isIncome
                  ? Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.12)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),

              shape: BoxShape.circle,
            ),

            child: Center(
              child: Icon(
                transaction.icon,
                size: 22,
                color: isIncome
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// TITLE + CATEGORY
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  transaction.title,

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${transaction.category} • ${transaction.date}",

                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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

              color: isIncome
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
