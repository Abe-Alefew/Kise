import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'app_dimensions.dart';
import 'text_theme.dart';

abstract class AppTheme {
  
  // LIGHT THEME
  
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',

        //Color Scheme 
        colorScheme: const ColorScheme.light(
          primary: AppColorsLight.primary,
          onPrimary: AppColorsLight.textOnPrimary,
          primaryContainer: AppColorsLight.primaryLight,
          onPrimaryContainer: AppColorsLight.primaryDark,
          secondary: AppColorsLight.secondaryBg,
          onSecondary: AppColorsLight.textHeading,
          surface: AppColorsLight.card,
          onSurface: AppColorsLight.textBody,
          surfaceContainerHighest: AppColorsLight.secondaryBg,
          error: AppColorsLight.error,
          onError: AppColorsLight.textOnPrimary,
        ),

        scaffoldBackgroundColor: AppColorsLight.scaffold,
        cardColor: AppColorsLight.card,

        // Text Theme 
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.h1,
          displayMedium: AppTextStyles.h2,
          displaySmall: AppTextStyles.h3,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.bodySm,
          bodySmall: AppTextStyles.micro,
          labelMedium: AppTextStyles.label,
          labelSmall: AppTextStyles.micro,
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsLight.primary,
            foregroundColor: AppColorsLight.textOnPrimary,
            disabledBackgroundColor: AppColorsLight.primaryLight,
            disabledForegroundColor: AppColorsLight.textOnPrimary,
            textStyle: AppTextStyles.buttonText,
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),

        //OutlinedButton ──
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorsLight.primary,
            disabledForegroundColor: AppColorsLight.primaryLight,
            textStyle: AppTextStyles.buttonText.copyWith(
              color: AppColorsLight.primary,
            ),
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            side: const BorderSide(
              color: AppColorsLight.primary,
              width: AppDimensions.inputBorderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
          ),
        ),

        // ── TextButton ────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsLight.primary,
            textStyle: AppTextStyles.bodySm.copyWith(
              color: AppColorsLight.primary,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
          ),
        ),

        //InputDecoration 
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsLight.inputFill,
          hintStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsLight.textHint,
          ),
          labelStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsLight.textBody,
          ),
          errorStyle: AppTextStyles.micro.copyWith(
            color: AppColorsLight.error,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          // Default (unfocused, no error)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsLight.textHint,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          // Enabled, unfocused
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsLight.textHint.withValues(alpha: 0.4),
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          // Focused
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsLight.primary,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          // Error, unfocused
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsLight.error,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          // Error, focused
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsLight.error,
              width: AppDimensions.inputBorderWidth + 0.5,
            ),
          ),
          // Disabled
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsLight.textHint.withValues(alpha: 0.2),
              width: AppDimensions.inputBorderWidth,
            ),
          ),
        ),

        // ── Card ──────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColorsLight.card,
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── AppBar ────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsLight.scaffold,
          foregroundColor: AppColorsLight.textHeading,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.h3,
          iconTheme: const IconThemeData(
            color: AppColorsLight.textHeading,
            size: 24,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // dark icons on light bg
          ),
        ),

        // ── SnackBar ──────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorsLight.textHeading, // dark bg
          contentTextStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsLight.card,
          ),
          actionTextColor: AppColorsLight.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
        ),

        // ── BottomNavigationBar ───────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColorsLight.card,
          selectedItemColor: AppColorsLight.primary,
          unselectedItemColor: AppColorsLight.textHint,
          selectedLabelStyle: AppTextStyles.micro,
          unselectedLabelStyle: AppTextStyles.micro,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // ── Divider ───────────────────────────────
        dividerTheme: DividerThemeData(
          color: AppColorsLight.textHint.withValues(alpha: 0.2),
          thickness: 1,
          space: 1,
        ),

        // ── Chip ──────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColorsLight.secondaryBg,
          selectedColor: AppColorsLight.primary,
          labelStyle: AppTextStyles.label,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.sm,
            vertical: AppDimensions.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          side: BorderSide.none,
        ),

        // ── FloatingActionButton ──────────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: AppColorsLight.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),

        // ── ListTile ──────────────────────────────
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
          ),
          titleTextStyle: AppTextStyles.bodyLg,
          subtitleTextStyle: AppTextStyles.bodySm,
          iconColor: AppColorsLight.textBody,
        ),
      );

  // ─────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',

        // ── Color Scheme ──────────────────────────
        colorScheme: const ColorScheme.dark(
          primary: AppColorsDark.primary,
          onPrimary: AppColorsDark.textOnPrimary,
          secondary: AppColorsDark.secondaryBg,
          onSecondary: AppColorsDark.textHeading,
          surface: AppColorsDark.card,
          onSurface: AppColorsDark.textBody,
          error: AppColorsDark.error,
          onError: AppColorsDark.textHeading,
        ),

        scaffoldBackgroundColor: AppColorsDark.scaffold,
        cardColor: AppColorsDark.card,

        // ── Text Theme ────────────────────────────
        textTheme: TextTheme(
          displayLarge: AppTextStyles.h1.copyWith(color: AppColorsDark.textHeading),
          displayMedium: AppTextStyles.h2.copyWith(color: AppColorsDark.textHeading),
          displaySmall: AppTextStyles.h3.copyWith(color: AppColorsDark.textHeading),
          bodyLarge: AppTextStyles.bodyLg.copyWith(color: AppColorsDark.textBody),
          bodyMedium: AppTextStyles.bodySm.copyWith(color: AppColorsDark.textBody),
          bodySmall: AppTextStyles.micro.copyWith(color: AppColorsDark.textHint),
          labelMedium: AppTextStyles.label.copyWith(color: AppColorsDark.textBody),
          labelSmall: AppTextStyles.micro.copyWith(color: AppColorsDark.textHint),
        ),

        // ── ElevatedButton ────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsDark.primary,
            foregroundColor: AppColorsDark.textOnPrimary,
            textStyle: AppTextStyles.buttonText.copyWith(
              color: AppColorsDark.textOnPrimary,
            ),
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),

        // ── OutlinedButton ────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorsDark.primary,
            textStyle: AppTextStyles.buttonText.copyWith(
              color: AppColorsDark.primary,
            ),
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            side: const BorderSide(
              color: AppColorsDark.primary,
              width: AppDimensions.inputBorderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
          ),
        ),

        // ── TextButton ────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsDark.primary,
            textStyle: AppTextStyles.bodySm.copyWith(
              color: AppColorsDark.primary,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
          ),
        ),

        // ── InputDecoration ───────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsDark.inputFill,
          hintStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsDark.textHint,
          ),
          labelStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsDark.textBody,
          ),
          errorStyle: AppTextStyles.micro.copyWith(
            color: AppColorsDark.error,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsDark.border,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsDark.border.withValues(alpha: 0.6),
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsDark.primary,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColorsDark.error,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsDark.error,
              width: AppDimensions.inputBorderWidth + 0.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColorsDark.border.withValues(alpha: 0.3),
              width: AppDimensions.inputBorderWidth,
            ),
          ),
        ),

        // ── Card ──────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColorsDark.card,
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── AppBar ────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsDark.scaffold,
          foregroundColor: AppColorsDark.textHeading,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.h3.copyWith(
            color: AppColorsDark.textHeading,
          ),
          iconTheme: const IconThemeData(
            color: AppColorsDark.textHeading,
            size: 24,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, // light icons on dark bg
          ),
        ),

        // ── SnackBar ──────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorsDark.card,
          contentTextStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsDark.textHeading,
          ),
          actionTextColor: AppColorsDark.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
        ),

        // ── BottomNavigationBar ───────────────────
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColorsDark.card,
          selectedItemColor: AppColorsDark.primary,
          unselectedItemColor: AppColorsDark.textHint,
          selectedLabelStyle: AppTextStyles.micro,
          unselectedLabelStyle: AppTextStyles.micro,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // ── Divider ───────────────────────────────
        dividerTheme: DividerThemeData(
          color: AppColorsDark.border.withValues(alpha: 0.5),
          thickness: 1,
          space: 1,
        ),

        // ── Chip ──────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColorsDark.secondaryBg,
          selectedColor: AppColorsDark.primary,
          labelStyle: AppTextStyles.label.copyWith(
            color: AppColorsDark.textBody,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.sm,
            vertical: AppDimensions.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          side: BorderSide.none,
        ),

        // ── FloatingActionButton ──────────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),

        // ── ListTile ──────────────────────────────
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
          ),
          titleTextStyle: AppTextStyles.bodyLg.copyWith(
            color: AppColorsDark.textHeading,
          ),
          subtitleTextStyle: AppTextStyles.bodySm.copyWith(
            color: AppColorsDark.textBody,
          ),
          iconColor: AppColorsDark.textBody,
        ),
      );
}