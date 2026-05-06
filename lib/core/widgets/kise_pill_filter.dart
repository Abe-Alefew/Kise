import 'package:flutter/material.dart';

class KisePillFilter extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelected;

  final double? height;
  final double? width;

  const KisePillFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;

          return Container(
            key: ValueKey(option),
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? const Color(0xFFDDA22C) : Color(0XFFF2F4F0),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(option),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width != null ? 0 : 16,
                    vertical: height != null ? 0 : 6,
                  ),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Color(0xFF8D888A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
