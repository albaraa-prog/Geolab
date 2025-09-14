import 'package:flutter/material.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/config/theme_service.dart';

/// Utility class for easy theme access throughout the app
class AppThemeUtils {
  static ThemeService get _service => ThemeService.instance;

  /// Get current theme
  static ThemeData get currentTheme => _service.currentTheme;

  /// Check if current theme is dark
  static bool get isDarkMode => _service.isDarkMode;

  /// Get theme mode
  static ThemeMode get themeMode => _service.themeMode;

  /// Get brightness
  static Brightness get brightness => _service.brightness;

  /// Get primary color
  static Color get primaryColor => _service.primaryColor;

  /// Get background color
  static Color get backgroundColor => _service.backgroundColor;

  /// Get surface color
  static Color get surfaceColor => _service.surfaceColor;

  /// Get text color
  static Color get textColor => _service.textColor;

  /// Get card color
  static Color get cardColor => _service.cardColor;

  /// Get divider color
  static Color get dividerColor => _service.dividerColor;

  /// Get input decoration theme
  static InputDecorationThemeData get inputDecorationTheme => _service.inputDecorationTheme;

  /// Get elevated button theme
  static ElevatedButtonThemeData get elevatedButtonTheme => _service.elevatedButtonTheme;

  /// Get outlined button theme
  static OutlinedButtonThemeData get outlinedButtonTheme => _service.outlinedButtonTheme;

  /// Get text button theme
  static TextButtonThemeData get textButtonTheme => _service.textButtonTheme;

  /// Get switch theme
  static SwitchThemeData get switchTheme => _service.switchTheme;

  /// Get card theme
  static CardThemeData get cardTheme => _service.cardTheme;

  /// Get app bar theme
  static AppBarThemeData get appBarTheme => _service.appBarTheme;

  /// Get text theme
  static TextTheme get textTheme => _service.textTheme;

  /// Get divider theme
  static DividerThemeData get dividerTheme => _service.dividerTheme;

  /// Toggle theme
  static Future<void> toggleTheme() => _service.toggleTheme();

  /// Set theme
  static Future<void> setTheme(bool isDarkMode) => _service.setTheme(isDarkMode);

  /// Set system theme preference
  static Future<void> setUseSystemTheme(bool useSystem) => _service.setUseSystemTheme(useSystem);

  /// Check if system theme should be used
  static bool get useSystemTheme => _service.useSystemTheme;
}

/// Extension for BuildContext to easily access theme
extension ThemeExtension on BuildContext {
  /// Check if current theme is dark
  bool get isDarkMode => AppThemeUtils.isDarkMode;

  /// Get current brightness
  Brightness get brightness => AppThemeUtils.brightness;

  /// Get primary color
  Color get primaryColor => AppThemeUtils.primaryColor;

  /// Get background color
  Color get backgroundColor => AppThemeUtils.backgroundColor;

  /// Get surface color
  Color get surfaceColor => AppThemeUtils.surfaceColor;

  /// Get text color
  Color get textColor => AppThemeUtils.textColor;

  /// Get card color
  Color get cardColor => AppThemeUtils.cardColor;

  /// Get divider color
  Color get dividerColor => AppThemeUtils.dividerColor;
}

/// Common theme constants
class AppThemeConstants {
  // Colors
  static const Color primaryColor = AppTheme.primaryColor;
  static const Color primaryLightColor = AppTheme.primaryLightColor;
  static const Color primaryDarkColor = AppTheme.primaryDarkColor;
  static const Color secondaryColor = AppTheme.secondaryColor;
  static const Color secondaryLightColor = AppTheme.secondaryLightColor;
  static const Color secondaryDarkColor = AppTheme.secondaryDarkColor;
  static const Color accentColor = AppTheme.accentColor;
  static const Color accentLightColor = AppTheme.accentLightColor;
  static const Color accentDarkColor = AppTheme.accentDarkColor;

  // Neutral Colors
  static const Color neutral50 = AppTheme.neutral50;
  static const Color neutral100 = AppTheme.neutral100;
  static const Color neutral200 = AppTheme.neutral200;
  static const Color neutral300 = AppTheme.neutral300;
  static const Color neutral400 = AppTheme.neutral400;
  static const Color neutral500 = AppTheme.neutral500;
  static const Color neutral600 = AppTheme.neutral600;
  static const Color neutral700 = AppTheme.neutral700;
  static const Color neutral800 = AppTheme.neutral800;
  static const Color neutral900 = AppTheme.neutral900;

  // Status Colors
  static const Color successColor = AppTheme.successColor;
  static const Color warningColor = AppTheme.warningColor;
  static const Color errorColor = AppTheme.errorColor;
  static const Color infoColor = AppTheme.infoColor;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Font Sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;
  static const double fontSizeXXXL = 24.0;
  static const double fontSizeDisplay = 32.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve curveFast = Curves.easeInOut;
  static const Curve curveNormal = Curves.easeInOutCubic;
  static const Curve curveSlow = Curves.easeInOutQuart;
}

/// Theme-aware color utilities
class ThemeAwareColors {
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getOnPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color getOnSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getOnBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getOnErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

  static Color getOutlineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color getOutlineVariantColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  static Color getInversePrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.inversePrimary;
  }

  static Color getInverseSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.inverseSurface;
  }

  static Color getInverseOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getShadowColor(BuildContext context) {
    return Theme.of(context).colorScheme.shadow;
  }

  static Color getScrimColor(BuildContext context) {
    return Theme.of(context).colorScheme.scrim;
  }

  static Color getTertiaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  static Color getOnTertiaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiary;
  }

  static Color getTertiaryContainerColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiaryContainer;
  }

  static Color getOnTertiaryContainerColor(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiaryContainer;
  }
}
