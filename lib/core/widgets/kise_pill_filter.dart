import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_theme_ext.dart';
import 'package:kise/core/theme/colors.dart';

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final bool isSelected = option == selected;

          Color pillColor;

          if (!isSelected) {
            pillColor = isDark ? AppColorsDark.secondaryBg : AppColorsLight.secondaryBg;
          } else {
            pillColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;
          }

          return Container(
            key: ValueKey(option),
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? context.kisePrimary : context.kiseSecondaryBg,
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
                          color: isSelected ? Colors.white : context.kiseTextBody,
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
