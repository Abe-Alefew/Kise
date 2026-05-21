import 'package:flutter/material.dart';
import 'package:kise/core/theme/colors.dart';

extension AppThemeX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get kiseCard        => _isDark ? AppColorsDark.card        : AppColorsLight.card;
  Color get kiseSecondaryBg => _isDark ? AppColorsDark.secondaryBg : AppColorsLight.secondaryBg;

  Color get kiseTextHeading  => _isDark ? AppColorsDark.textHeading  : AppColorsLight.textHeading;
  Color get kiseTextBody     => _isDark ? AppColorsDark.textBody     : AppColorsLight.textBody;
  Color get kiseTextHint     => _isDark ? AppColorsDark.textHint     : AppColorsLight.textHint;

  Color get kisePrimary => _isDark ? AppColorsDark.primary : AppColorsLight.primary;
  Color get kiseError   => _isDark ? AppColorsDark.error   : AppColorsLight.error;
  Color get kiseSuccess => _isDark ? AppColorsDark.success : AppColorsLight.success;

  Color get kiseLentCardBg       => _isDark ? AppColorsDark.lentCardBg       : AppColorsLight.lentCardBg;
  Color get kiseLentCardIcon     => _isDark ? AppColorsDark.lentCardIcon     : AppColorsLight.lentCardIcon;
  Color get kiseBorrowedCardBg   => _isDark ? AppColorsDark.borrowedCardBg   : AppColorsLight.borrowedCardBg;
  Color get kiseBorrowedCardIcon => _isDark ? AppColorsDark.borrowedCardIcon : AppColorsLight.borrowedCardIcon;
  Color get kiseSettledCardBg    => _isDark ? AppColorsDark.settledCardBg    : AppColorsLight.settledCardBg;
  Color get kiseSettledCardIcon  => _isDark ? AppColorsDark.settledCardIcon  : AppColorsLight.settledCardIcon;

  Color get kisePendingChart => _isDark ? AppColorsDark.pendingChart : AppColorsLight.pendingChart;
  Color get kisePartialChart => _isDark ? AppColorsDark.partialChart : AppColorsLight.partialChart;
  Color get kiseSettledChart => _isDark ? AppColorsDark.settledChart : AppColorsLight.settledChart;
}
