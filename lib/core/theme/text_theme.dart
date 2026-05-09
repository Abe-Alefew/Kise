import 'package:flutter/material.dart';
import 'colors.dart';

abstract class AppTextStyles {
  static const String _fontFamily = 'Inter'; 

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36, // mapped from text-4xl
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textHeading,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24, // mapped from text-2xl
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textHeading,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18, // mapped from text-lg
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textHeading,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16, // mapped from text-base
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textBody,
    height: 1.6,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14, // mapped from text-sm
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textBody,
    height: 1.5,
  );

  // Special
  static const TextStyle amountLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30, // mapped from text-3xl
    fontWeight: FontWeight.w800,
    color: AppColorsLight.textHeading,
    letterSpacing: -0.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12, // mapped from text-xs
    fontWeight: FontWeight.w500,
    color: AppColorsLight.textBody,
    letterSpacing: 0.2,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10, // mapped from text-[10px]
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textHint,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textOnPrimary,
    letterSpacing: 0.3,
  );
}