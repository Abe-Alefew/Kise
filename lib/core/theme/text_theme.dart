import 'package:flutter/material.dart';
import 'colors.dart';

abstract class _AppTextStylesCommon {
  static const String fontFamily = 'Inter'; 

  // h1
  static const double h1Size = 36;
  static const FontWeight h1Weight = FontWeight.w700;
  static const double h1Height = 1.3;

  // h2
  static const double h2Size = 24;
  static const FontWeight h2Weight = FontWeight.w700;
  static const double h2Height = 1.3;

  // h3
  static const double h3Size = 18;
  static const FontWeight h3Weight = FontWeight.w600;

  // bodyLg
  static const double bodyLgSize = 16;
  static const FontWeight bodyLgWeight = FontWeight.w400;
  static const double bodyLgHeight = 1.6;

  // bodySm
  static const double bodySmSize = 14;
  static const FontWeight bodySmWeight = FontWeight.w400;
  static const double bodySmHeight = 1.5;

  // amountLg
  static const double amountLgSize = 30;
  static const FontWeight amountLgWeight = FontWeight.w800;
  static const double amountLgSpacing = -0.5;

  // label
  static const double labelSize = 12;
  static const FontWeight labelWeight = FontWeight.w500;
  static const double labelSpacing = 0.2;

  // micro
  static const double microSize = 10;
  static const FontWeight microWeight = FontWeight.w400;

  // buttonText
  static const double buttonTextSize = 16;
  static const FontWeight buttonTextWeight = FontWeight.w600;
  static const double buttonTextSpacing = 0.3;
}

abstract class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h1Size,
    fontWeight: _AppTextStylesCommon.h1Weight,
    height: _AppTextStylesCommon.h1Height,
    color: AppColorsLight.textHeading,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h2Size,
    fontWeight: _AppTextStylesCommon.h2Weight,
    height: _AppTextStylesCommon.h2Height,
    color: AppColorsLight.textHeading,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h3Size,
    fontWeight: _AppTextStylesCommon.h3Weight,
    color: AppColorsLight.textHeading,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.bodyLgSize,
    fontWeight: _AppTextStylesCommon.bodyLgWeight,
    height: _AppTextStylesCommon.bodyLgHeight,
    color: AppColorsLight.textBody,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.bodySmSize,
    fontWeight: _AppTextStylesCommon.bodySmWeight,
    height: _AppTextStylesCommon.bodySmHeight,
    color: AppColorsLight.textBody,
  );

  // Special
  static const TextStyle amountLg = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.amountLgSize,
    fontWeight: _AppTextStylesCommon.amountLgWeight,
    letterSpacing: _AppTextStylesCommon.amountLgSpacing,
    color: AppColorsLight.textHeading,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.labelSize,
    fontWeight: _AppTextStylesCommon.labelWeight,
    letterSpacing: _AppTextStylesCommon.labelSpacing,
    color: AppColorsLight.textBody,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.microSize,
    fontWeight: _AppTextStylesCommon.microWeight,
    color: AppColorsLight.textHint,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.buttonTextSize,
    fontWeight: _AppTextStylesCommon.buttonTextWeight,
    letterSpacing: _AppTextStylesCommon.buttonTextSpacing,
    color: AppColorsLight.textOnPrimary,
  );
}

abstract class AppTextStylesDark {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h1Size,
    fontWeight: _AppTextStylesCommon.h1Weight,
    height: _AppTextStylesCommon.h1Height,
    color: AppColorsDark.textHeading,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h2Size,
    fontWeight: _AppTextStylesCommon.h2Weight,
    height: _AppTextStylesCommon.h2Height,
    color: AppColorsDark.textHeading,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.h3Size,
    fontWeight: _AppTextStylesCommon.h3Weight,
    color: AppColorsDark.textHeading,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.bodyLgSize,
    fontWeight: _AppTextStylesCommon.bodyLgWeight,
    height: _AppTextStylesCommon.bodyLgHeight,
    color: AppColorsDark.textBody,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.bodySmSize,
    fontWeight: _AppTextStylesCommon.bodySmWeight,
    height: _AppTextStylesCommon.bodySmHeight,
    color: AppColorsDark.textBody,
  );

  // Special
  static const TextStyle amountLg = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.amountLgSize,
    fontWeight: _AppTextStylesCommon.amountLgWeight,
    letterSpacing: _AppTextStylesCommon.amountLgSpacing,
    color: AppColorsDark.textHeading,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.labelSize,
    fontWeight: _AppTextStylesCommon.labelWeight,
    letterSpacing: _AppTextStylesCommon.labelSpacing,
    color: AppColorsDark.textBody,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.microSize,
    fontWeight: _AppTextStylesCommon.microWeight,
    color: AppColorsDark.textHint,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: _AppTextStylesCommon.fontFamily,
    fontSize: _AppTextStylesCommon.buttonTextSize,
    fontWeight: _AppTextStylesCommon.buttonTextWeight,
    letterSpacing: _AppTextStylesCommon.buttonTextSpacing,
    color: AppColorsDark.textOnPrimary,
  );
}