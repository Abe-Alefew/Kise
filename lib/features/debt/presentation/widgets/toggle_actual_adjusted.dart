import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';

class ToggleActualAdjusted extends StatelessWidget {
  final bool isActual;
  final ValueChanged<bool> onChanged;

  const ToggleActualAdjusted({
    super.key,
    required this.isActual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Actual',
            selected: isActual,
            isLeft: true,
            onTap: () => onChanged(true),
          ),
          _Segment(
            label: 'Adjusted',
            selected: !isActual,
            isLeft: false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Active fill rounds only the outer corners — flat edge faces the other segment.
    final activeBorderRadius = isLeft
        ? const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusMd),
            bottomLeft: Radius.circular(AppDimensions.radiusMd),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(AppDimensions.radiusMd),
            bottomRight: Radius.circular(AppDimensions.radiusMd),
          );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm - 2,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: selected ? activeBorderRadius : BorderRadius.zero,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: selected
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
        ),
      ),
    );
  }
}
