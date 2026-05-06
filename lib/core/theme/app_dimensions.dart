import 'package:flutter/material.dart';

abstract class AppDimensions {
  // Spacing scale (8pt grid)
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;

  // Border radius
  static const double radiusSm      = 8.0;
  static const double radiusMd      = 12.0;
  static const double radiusLg      = 16.0;
  static const double radiusRound   = 100.0;  // pill buttons

  // Component sizing
  static const double buttonHeight       = 52.0;
  static const double inputHeight        = 56.0;
  static const double inputBorderWidth   = 1.5;

  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );
}