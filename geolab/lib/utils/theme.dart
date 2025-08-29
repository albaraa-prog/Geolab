import 'package:flutter/material.dart';

/// Example usage of AppAlerts with AppTheme:
///
/// ```dart
/// // Show an alert dialog with themed colors
/// AppAlerts.showAlert(context, 'Title', 'This is a message');
///
/// // Show a snackbar with the primary color
/// AppAlerts.showSnackbar(context, 'This is a snackbar');
///
/// // Show a bottom sheet with custom content
/// AppAlerts.showBottomSheet(context, YourCustomWidget());
/// ```
///
/// The AppAlerts class uses AppTheme colors for consistency.
///
class AppTheme {
  static const Color primary = Color(0xFF795548); // Brown 600
  static const Color primaryLight = Color(0xFFA98274); // Brown 400
  static const Color primaryDark = Color(0xFF4B2C20); // Brown 800
  static const Color onPrimary = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: primary,
          fontSize: 24,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: primary,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF424242),
          fontSize: 16,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFFFFA726), // Orange 400
        surface: surface,
        onPrimary: onPrimary,
        onSurface: Color(0xFF424242),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }
}
