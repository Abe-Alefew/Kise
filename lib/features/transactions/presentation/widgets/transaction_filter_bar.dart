import 'package:flutter/material.dart';

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

    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      child: Row(

        children: filters.map((filter) {

          final bool isSelected =
              filter == selectedFilter;

          return GestureDetector(

            onTap: () => onSelected(filter),

            child: Container(

              margin: const EdgeInsets.only(right: 10),

              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),

              decoration: BoxDecoration(

                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(30),

                border: Border.all(
                  color: const Color(0xFFD4AF37),
                ),
              ),

              child: Text(

                filter,

                style: TextStyle(

                  fontWeight: FontWeight.w500,

                  color:
                      isSelected
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          );

        }).toList(),
      ),
    );
  }
}