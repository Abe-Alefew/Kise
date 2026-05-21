import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';

class WarningActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Color? color;

  const WarningActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.error;
    
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(
          color: effectiveColor, 
          width: AppDimensions.inputBorderWidth
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}
