import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final unselectedBg = isDark
        ? AppColorsDark.secondaryBg
        : AppColorsLight.secondaryBg;
    final unselectedText = isDark
        ? AppColorsDark.textBody
        : AppColorsLight.textBody;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;

          return Container(
            key: ValueKey(option),
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? primaryColor : unselectedBg,
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
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? onPrimaryColor : unselectedText,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
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
