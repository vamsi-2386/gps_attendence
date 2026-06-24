import 'package:flutter/material.dart';

/// Lumenor HRMS Theme Configuration
///
/// This file defines all theme constants and styling for the application.
/// Color scheme uses dark background with accent elements for HRMS.
class AppTheme {
  // Dark Theme Base Colors
  static const Color darkBackground = Color(0xFF000000); // Pure black
  static const Color darkElements = Color(0xFF212225); // Dark gray for elements
  static const Color textPrimary = Color(0xFFB0B4BA); // Light gray text
  static const Color textSecondary = Color(0xFF60646C); // Muted text
  static const Color borders = Color(0xFF60646C); // Border color

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // Green for success
  static const Color errorColor = Color(0xFFEF4444); // Red for errors
  static const Color warningColor = Color(0xFFF59E0B); // Amber for warnings
  static const Color infoColor = Color(0xFF3B82F6); // Blue for info

  // Accent Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo (primary)
  static const Color secondaryColor = Color(0xFF8B5CF6); // Violet (secondary)
  static const Color accentColor = Color(0xFF10B981); // Emerald (accent)

  // Neutral Colors for fallback
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF212225);
  static const Color mediumGray = Color(0xFF60646C);
  static const Color lightGray = Color(0xFFB0B4BA);
  static const Color veryLightGray = Color(0xFFF5F5F5);

  // Typography
  static const String fontFamilyPrimary = 'Roboto';

  // Text Styles - Optimized for dark theme
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    fontFamily: fontFamilyPrimary,
  );

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevation/Shadow
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  /// Material Theme Data - Dark Theme optimized for HRMS
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkElements,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: darkElements,
        surfaceContainer: darkElements,
        outline: textSecondary,
        outlineVariant: borders,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkElements,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: elevationSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElements,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borders),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borders),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        hintStyle: bodyMedium.copyWith(color: textSecondary),
        labelStyle: bodyMedium.copyWith(color: textPrimary),
        helperStyle: bodySmall.copyWith(color: textSecondary),
        errorStyle: bodySmall.copyWith(color: errorColor),
      ),
      cardTheme: CardThemeData(
        color: darkElements,
        elevation: elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: borders, width: 0.5),
        ),
        margin: const EdgeInsets.all(spacingSmall),
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelSmall: labelSmall,
      ),
    );
  }

  /// Shadow for cards and elevated surfaces
  static List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: black.withValues(alpha: 0.3),
          blurRadius: elevationMedium,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> elevatedShadow() => [
        BoxShadow(
          color: black.withValues(alpha: 0.4),
          blurRadius: elevationLarge,
          offset: const Offset(0, 4),
        ),
      ];

  /// Status color getter for UI components
  static Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'checked_in':
      case 'present':
        return successColor;
      case 'rejected':
      case 'absent':
      case 'checked_out':
        return errorColor;
      case 'pending':
      case 'late':
        return warningColor;
      default:
        return infoColor;
    }
  }
}
