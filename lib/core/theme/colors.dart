import 'package:flutter/material.dart';

// Raw palette mapped from Figma RGB values
abstract class _KisePalette {
  // Brand
  static const Color gold400 = Color(0xFFDDA22C); // primary
  static const Color gold300 = Color(0xFFE0C285); // Gold Light
  static const Color gold600 = Color(0xFFAF7E1D); // Gold Dark

  // Neutrals (Light Mode)
  static const Color slate900 = Color(0xFF1C1A17); // main_text_color
  static const Color slate600 = Color(0xFF8D888A); // secondary text color
  static const Color slate300 = Color(0xFF78736D); // muted foreground
  
  // Backgrounds
  static const Color offWhite = Color(0xFFFBFAF9); // background
  static const Color pureWhite = Color(0xFFFFFFFF); // white / card
  static const Color cream100 = Color(0xFFF4F1EC); // secondary / accent
  
  // Semantic
  static const Color error   = Color(0xFFDF3A3A); // Destructive
  static const Color success = Color(0xFF2BAB68); // Success

  // Debt feature card tints
  static const Color skyBlue50  = Color(0xFFEFF6FD); // lent card bg
  static const Color blue600    = Color(0xFF1976D2); // lent card icon
  static const Color peach50    = Color(0xFFFFF6EE); // borrowed card bg
  static const Color orange600  = Color(0xFFE65100); // borrowed card icon
  static const Color green50    = Color(0xFFEAF7F0); // settled card bg

}

// Private palette for Dark Mode values 
abstract class _KiseDarkPalette {
  static const Color charcoal900 = Color(0xFF111318); // background-darkmode
  static const Color charcoal800 = Color(0xFF1A1D24); // Card-darkmode
  static const Color charcoal700 = Color(0xFF252933); // secondary-darkmode
  
  static const Color gold400     = Color(0xFFDDA22C); // primary (shared)
  
  static const Color cream100    = Color(0xFFF5F2EC); // foreground-darkmode
  static const Color offWhite    = Color(0xFFFFFEF1); // main_text_color-darkmode
  static const Color roseGrey    = Color(0xFFD7CECE); // secondary-text-darkmode
  static const Color slateGrey   = Color(0xFF7A8194); // muted-foreground-darkmode

  static const Color errorRed    = Color(0xFFA33030); // destructive-darkmode
  static const Color successGreen = Color(0xFF2D8A5E); // success-darkmode
}

// Semantic layer for Dark Mode
abstract class AppColorsDark {
  // Brand
  static const Color primary      = _KiseDarkPalette.gold400;

  // Backgrounds
  static const Color scaffold     = _KiseDarkPalette.charcoal900;
  static const Color card         = _KiseDarkPalette.charcoal800;
  static const Color inputFill    = Color(0x4D252933); // Dark-input (30% opacity)
  static const Color secondaryBg  = _KiseDarkPalette.charcoal700;

  // Text
  static const Color textHeading  = _KiseDarkPalette.offWhite;
  static const Color textBody     = _KiseDarkPalette.roseGrey;
  static const Color textHint     = _KiseDarkPalette.slateGrey;
  static const Color textOnPrimary = Color(0xFF000000); // Usually black for contrast on gold

  // Semantic
  static const Color error        = _KiseDarkPalette.errorRed;
  static const Color success      = _KiseDarkPalette.successGreen;
  static const Color border       = _KiseDarkPalette.charcoal700;

  // Debt feature card tints (dark variants)
  static const Color lentCardBg      = Color(0xFF152233);
  static const Color lentCardIcon    = Color(0xFF64B5F6);
  static const Color borrowedCardBg  = Color(0xFF2A1A08);
  static const Color borrowedCardIcon = Color(0xFFFFB74D);
  static const Color settledCardBg   = Color(0xFF0D2B1A);
  static const Color settledCardIcon = Color(0xFF81C784);

  // Analytics chart segment colors (dark mode)
  static const Color pendingChart    = Color(0xFFFF8A65);
  static const Color partialChart    = Color(0xFF90CAF9);
  static const Color settledChart    = Color(0xFFA5D6A7);
}

// Semantic layer — what widgets actually import
abstract class AppColorsLight {
  // Brand
  static const Color primary      = _KisePalette.gold400;
  static const Color primaryLight = _KisePalette.gold300;
  static const Color primaryDark  = _KisePalette.gold600;

  // Backgrounds
  static const Color scaffold     = _KisePalette.offWhite;
  static const Color card         = _KisePalette.pureWhite;
  static const Color inputFill    = _KisePalette.offWhite;
  static const Color secondaryBg  = _KisePalette.cream100;

  // Text
  static const Color textHeading  = _KisePalette.slate900;
  static const Color textBody     = _KisePalette.slate600;
  static const Color textHint     = _KisePalette.slate300;
  static const Color textOnPrimary = _KisePalette.pureWhite;

  // Semantic
  static const Color error        = _KisePalette.error;
  static const Color success      = _KisePalette.success;

  // Debt feature card tints
  static const Color lentCardBg      = _KisePalette.skyBlue50;
  static const Color lentCardIcon    = _KisePalette.blue600;
  static const Color borrowedCardBg  = _KisePalette.peach50;
  static const Color borrowedCardIcon = _KisePalette.orange600;
  static const Color settledCardBg   = _KisePalette.green50;
  static const Color settledCardIcon = _KisePalette.success;

  // Analytics chart segment colors (full-saturation, 100% opacity)
  static const Color pendingChart  = _KisePalette.orange600;
  static const Color partialChart  = _KisePalette.blue600;
  static const Color settledChart  = _KisePalette.success;
}