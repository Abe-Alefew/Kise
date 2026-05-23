import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/home_dashboard_models.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<HomeRecentTransaction> transactions;
  final String currency;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.currency = 'ETB',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textHeading
                    : AppColorsLight.textHeading,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View all',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.primary
                      : AppColorsLight.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          KiseCardHolder(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent transactions',
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textHint
                        : AppColorsLight.textHint,
                  ),
                ),
              ),
            ),
          )
        else
          ...transactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KiseCardHolder(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForCategory(transaction.category),
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                  title: Text(
                    transaction.title.isNotEmpty
                        ? transaction.title
                        : transaction.category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textHeading
                          : AppColorsLight.textHeading,
                    ),
                  ),
                  subtitle: Text(
                    _subtitleFor(transaction),
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textHint
                          : AppColorsLight.textHint,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '${transaction.isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.isExpense
                          ? (isDark
                              ? AppColorsDark.textHeading
                              : AppColorsLight.textHeading)
                          : const Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _subtitleFor(HomeRecentTransaction transaction) {
    final parts = <String>[];
    if (transaction.note != null && transaction.note!.trim().isNotEmpty) {
      parts.add(transaction.note!.trim());
    }
    if (transaction.displayDate != null &&
        transaction.displayDate!.isNotEmpty) {
      parts.add(transaction.displayDate!);
    }
    return parts.isEmpty ? transaction.category : parts.join(' · ');
  }

  static IconData _iconForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('food')) return Icons.restaurant_outlined;
    if (normalized.contains('transport')) return Icons.directions_car_outlined;
    if (normalized.contains('education')) return Icons.school_outlined;
    if (normalized.contains('entertainment')) {
      return Icons.movie_outlined;
    }
    return Icons.receipt_long_outlined;
  }
}
