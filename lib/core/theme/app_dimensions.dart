import 'package:flutter/material.dart';

abstract class AppDimensions {
  // Spacing scale (8pt grid)
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xl2  = 36.0;
  static const double xxxl = 80.0;

  // Border radius
  static const double radiusSm      = 8.0;
  static const double radiusMd      = 12.0;
  static const double radiusLg      = 16.0;
  static const double radiusAuthButton = 10.0;
  static const double radiusAuthCard   = 39.0;
  static const double radiusRound   = 100.0;  // pill buttons

  // Component sizing
  static const double buttonHeight       = 52.0;
  static const double authButtonHeight   = 37.0;
  static const double authButtonWidth    = 181.0;
  static const double inputHeight        = 56.0;
  static const double inputBorderWidth   = 1.5;

  // Font sizes
  static const double fontSizeCaption = 13.0;

  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // Figma asset dimensions
  static const double logoWidth = 160.0;
  static const double logoHeight = 80.0;
  static const double onboarding1Width = 505.0;
  static const double onboarding1Height = 466.0;
  static const double onboarding2Width = 336.22;
  static const double onboarding2Height = 260.0;
  static const double onboarding3Width = 346.0;
  static const double onboarding3Height = 275.0;
}