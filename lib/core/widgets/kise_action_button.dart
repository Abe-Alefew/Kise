import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

// Variant Enum

enum KiseButtonVariant {
  primary,   // filled gold  — Sign In, Register, Next
  outline,   // gold border  — secondary actions
  ghost,     // text only    — Skip, Cancel
}

// KiseActionButton

class KiseActionButton extends StatelessWidget {
  const KiseActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = KiseButtonVariant.primary,
    this.leadingIcon,
    this.textColor,
    this.fontSize,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.expanded = true, // full-width by default
    this.borderRadius,
    this.textStyle,
    this.outlineBorderSide,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final KiseButtonVariant variant;
  final IconData? leadingIcon;
  final Color? textColor;
  final double? fontSize;
  final double? width;
  final double height;
  final bool expanded;
  final double? borderRadius;
  final TextStyle? textStyle;
  final BorderSide? outlineBorderSide;

  // ── Resolve effective callback ──────────────
  // Blocks tap during loading without extra flags
  VoidCallback? get _effectiveOnPressed =>
      isLoading ? null : onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget button = switch (variant) {
      KiseButtonVariant.primary => _PrimaryButton(
          label: label,
          onPressed: _effectiveOnPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          textColor: textColor,
          fontSize: fontSize,
          height: height,
          shrink: !expanded && width == null,
          borderRadius: borderRadius,
          textStyle: textStyle,
        ),
      KiseButtonVariant.outline => _OutlineButton(
          label: label,
          onPressed: _effectiveOnPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          textColor: textColor,
          fontSize: fontSize,
          height: height,
          shrink: !expanded && width == null,
          borderRadius: borderRadius,
          textStyle: textStyle,
          outlineBorderSide: outlineBorderSide,
        ),
      KiseButtonVariant.ghost => _GhostButton(
          label: label,
          onPressed: _effectiveOnPressed,
          isLoading: isLoading,
          textColor: textColor,
          fontSize: fontSize,
          height: height,
          borderRadius: borderRadius,
        ),
    };

    // Width logic:
    // expanded=true  → full width (default — login, register, onboarding)
    // width provided → fixed width (FAB-style add buttons)
    // neither        → shrink-wrap
    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}


// Primary Button  (filled gold)

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.height,
    this.leadingIcon,
    this.shrink = false,
    this.borderRadius,
    this.textStyle,
    this.textColor,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Color? textColor;
  final double? fontSize;
  final double height;
  final bool shrink;
  final double? borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius!))
        : null;
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: shape ?? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: shrink ? const EdgeInsets.symmetric(horizontal: 16) : const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: shrink ? Size.zero : Size.zero,
          tapTargetSize: shrink ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
          foregroundColor: textColor,
        ),
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
          textColor: textColor,
          fontSize: fontSize,
          spinnerColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}


// Outline Button  (gold border, no fill)

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.height,
    this.leadingIcon,
    this.shrink = false,
    this.borderRadius,
    this.textStyle,
    this.textColor,
    this.fontSize,
    this.outlineBorderSide,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Color? textColor;
  final double? fontSize;
  final double height;
  final bool shrink;
  final double? borderRadius;
  final TextStyle? textStyle;
  final BorderSide? outlineBorderSide;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius!))
        : null;
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: shape ?? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: shrink ? const EdgeInsets.symmetric(horizontal: 16) : const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: shrink ? Size.zero : Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
          foregroundColor: textColor,
          side: outlineBorderSide,
        ),
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
          textColor: textColor,
          fontSize: fontSize,
          spinnerColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}


// Ghost Button  (text only)

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.height,
    this.borderRadius,
    this.textColor,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? borderRadius;
  final Color? textColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius!))
        : null;
    // TextButtonTheme from app_theme.dart is inherited automatically
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: shape,
        ),
        child: _ButtonContent(
          label: label,
          isLoading: isLoading,
          textColor: textColor,
          fontSize: fontSize,
          spinnerColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}


// Shared Content  (icon + label OR spinner)

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.spinnerColor,
    this.leadingIcon,
    this.textColor,
    this.fontSize,
  });

  final String label;
  final bool isLoading;
  final Color spinnerColor;
  final IconData? leadingIcon;
  final Color? textColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    }

    if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: 18, color: textColor),
          const SizedBox(width: AppDimensions.sm),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: fontSize),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(color: textColor, fontSize: fontSize),
    );
  }
}