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
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.expanded = true, // full-width by default
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;   // null = auto-disabled
  final bool isLoading;
  final KiseButtonVariant variant;
  final IconData? leadingIcon;
  final double? width;
  final double height;
  final bool expanded;
  final double? borderRadius;

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
          height: height,
          borderRadius: borderRadius,
        ),
      KiseButtonVariant.outline => _OutlineButton(
          label: label,
          onPressed: _effectiveOnPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          height: height,
          borderRadius: borderRadius,
        ),
      KiseButtonVariant.ghost => _GhostButton(
          label: label,
          onPressed: _effectiveOnPressed,
          isLoading: isLoading,
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
    this.borderRadius, 
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final double height;
  final double? borderRadius;
  

  @override
  Widget build(BuildContext context) {
    // ElevatedButtonTheme from app_theme.dart is inherited automatically
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Allow compact use — parent SizedBox (width:/height:) controls the size.
          // Without this, the global theme's minimumSize: Size(∞, 52) fights
          // any fixed-width wrapper and causes layout overflow on small buttons.
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
          // spinner color — white on gold
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
    this.borderRadius, 
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final double height;
  final double? borderRadius;
  
  @override
  Widget build(BuildContext context) {
    // OutlinedButtonTheme from app_theme.dart is inherited automatically
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
          // spinner color — gold on transparent
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
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    // TextButtonTheme from app_theme.dart is inherited automatically
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: onPressed,
        child: _ButtonContent(
          label: label,
          isLoading: isLoading,
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
  });

  final String label;
  final bool isLoading;
  final Color spinnerColor;
  final IconData? leadingIcon;

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
          Icon(leadingIcon, size: 18),
          const SizedBox(width: AppDimensions.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}