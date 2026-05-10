import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_pill_filter.dart';

class TransactionsFilterBar extends StatelessWidget {

  final List<String> filters;
  final String selectedFilter;
  final Function(String) onSelected;

  const TransactionsFilterBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return KisePillFilter(
      options: filters,
      selected: selectedFilter,
      onSelected: onSelected,
    );
  }
}