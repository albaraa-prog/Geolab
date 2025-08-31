import 'package:flutter/material.dart';

class WebTheme {
  // Web-specific colors
  static const Color webPrimary = Color(0xFF1976D2);
  static const Color webSecondary = Color(0xFF42A5F5);
  static const Color webBackground = Color(0xFFFAFAFA);
  static const Color webSurface = Color(0xFFFFFFFF);
  static const Color webError = Color(0xFFD32F2F);
  static const Color webOnPrimary = Color(0xFFFFFFFF);
  static const Color webOnSecondary = Color(0xFFFFFFFF);
  static const Color webOnBackground = Color(0xFF212121);
  static const Color webOnSurface = Color(0xFF212121);
  static const Color webOnError = Color(0xFFFFFFFF);
  
  // Web-specific text styles
  static const TextStyle webHeadline1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: webOnBackground,
    letterSpacing: -0.5,
  );
  
  static const TextStyle webHeadline2 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: webOnBackground,
    letterSpacing: -0.25,
  );
  
  static const TextStyle webHeadline3 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: webOnBackground,
  );
  
  static const TextStyle webBody1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: webOnBackground,
    height: 1.5,
  );
  
  static const TextStyle webBody2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: webOnBackground,
    height: 1.4,
  );
  
  static const TextStyle webButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: webOnPrimary,
    letterSpacing: 0.5,
  );
  
  // Web-specific button styles
  static final ButtonStyle webPrimaryButton = ElevatedButton.styleFrom(
    backgroundColor: webPrimary,
    foregroundColor: webOnPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    shadowColor: webPrimary.withOpacity(0.3),
  );
  
  static final ButtonStyle webSecondaryButton = OutlinedButton.styleFrom(
    foregroundColor: webPrimary,
    side: const BorderSide(color: webPrimary, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  // Web-specific input decoration
  static final InputDecoration webInputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: webPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: webError),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: webError, width: 2),
    ),
    filled: true,
    fillColor: webSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF757575)),
  );
  
  // Web-specific card decoration
  static final BoxDecoration webCardDecoration = BoxDecoration(
    color: webSurface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Web-specific container decoration
  static final BoxDecoration webContainerDecoration = BoxDecoration(
    color: webSurface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
