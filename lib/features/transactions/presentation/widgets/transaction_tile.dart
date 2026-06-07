import 'package:flutter/material.dart';

import '../../domain/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDeleting;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type.toLowerCase() == "income";
    final cs = Theme.of(context).colorScheme;

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
                  ? cs.tertiary.withValues(alpha: 0.12)
                  : cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                transaction.icon,
                size: 22,
                color: isIncome ? cs.tertiary : cs.primary,
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
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${transaction.category} • ${transaction.date}",
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
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
              color: isIncome ? cs.tertiary : cs.error,
            ),
          ),

          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 4),
            if (isDeleting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18, color: cs.outline),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Edit',
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Delete',
                ),
            ],
          ],
        ],
      ),
    );
  }
}
