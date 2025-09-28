import 'package:flutter/material.dart';
import 'package:geolab/config/theme.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  static ThemeService get instance {
    _instance ??= ThemeService();
    return _instance!;
  }

  bool _isDarkMode = false;
  bool _isInitialized = true;
  bool _useSystemTheme = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeService() {
    // Initialize with default values (no persistence)
    _isInitialized = true;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> setTheme(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;
    _isDarkMode = isDarkMode;
    notifyListeners();
  }

  // Get theme mode for MaterialApp
  ThemeMode get themeMode {
    if (!_isInitialized) return ThemeMode.system;
    if (useSystemTheme) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Check if system theme should be used
  bool get useSystemTheme => _useSystemTheme;

  // Set system theme preference
  Future<void> setUseSystemTheme(bool useSystem) async {
    _useSystemTheme = useSystem;
    notifyListeners();
  }

  // Get theme brightness
  Brightness get brightness => _isDarkMode ? Brightness.dark : Brightness.light;

  // Get primary color based on current theme
  Color get primaryColor => _isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

  // Get background color based on current theme
  Color get backgroundColor => _isDarkMode ? AppTheme.neutral900 : AppTheme.neutral50;

  // Get surface color based on current theme
  Color get surfaceColor => _isDarkMode ? AppTheme.neutral800 : Colors.white;

  // Get text color based on current theme
  Color get textColor => _isDarkMode ? AppTheme.neutral100 : AppTheme.neutral900;

  // Get card color based on current theme
  Color get cardColor => _isDarkMode ? AppTheme.neutral800 : Colors.white;

  // Get divider color based on current theme
  Color get dividerColor => _isDarkMode ? AppTheme.neutral700 : AppTheme.neutral200;

  // Get on primary color based on current theme
  Color get onPrimaryColor => _isDarkMode ? AppTheme.neutral900 : Colors.white;

  // Get on surface color based on current theme
  Color get onSurfaceColor => _isDarkMode ? AppTheme.neutral100 : AppTheme.neutral900;

  // Get shadow color based on current theme
  Color get shadowColor => _isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);

  // Get error color based on current theme
  Color get errorColor => AppTheme.errorColor;

  // Get warning color based on current theme
  Color get warningColor => AppTheme.warningColor;

  // Get success color based on current theme
  Color get successColor => AppTheme.successColor;

  // Get info color based on current theme
  Color get infoColor => AppTheme.infoColor;

  // Get input decoration theme based on current theme
  InputDecorationThemeData get inputDecorationTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.inputDecorationTheme 
        : AppTheme.lightTheme.inputDecorationTheme;
  }

  // Get button theme based on current theme
  ElevatedButtonThemeData get elevatedButtonTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.elevatedButtonTheme 
        : AppTheme.lightTheme.elevatedButtonTheme;
  }

  // Get outlined button theme based on current theme
  OutlinedButtonThemeData get outlinedButtonTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.outlinedButtonTheme 
        : AppTheme.lightTheme.outlinedButtonTheme;
  }

  // Get text button theme based on current theme
  TextButtonThemeData get textButtonTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.textButtonTheme 
        : AppTheme.lightTheme.textButtonTheme;
  }

  // Get switch theme based on current theme
  SwitchThemeData get switchTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.switchTheme 
        : AppTheme.lightTheme.switchTheme;
  }

  // Get card theme based on current theme
  CardThemeData get cardTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.cardTheme 
        : AppTheme.lightTheme.cardTheme;
  }

  // Get app bar theme based on current theme
  AppBarThemeData get appBarTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.appBarTheme 
        : AppTheme.lightTheme.appBarTheme;
  }

  // Get text theme based on current theme
  TextTheme get textTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.textTheme 
        : AppTheme.lightTheme.textTheme;
  }

  // Get divider theme based on current theme
  DividerThemeData get dividerTheme {
    return _isDarkMode 
        ? AppTheme.darkTheme.dividerTheme 
        : AppTheme.lightTheme.dividerTheme;
  }

  // Handle system theme changes
  void handleSystemThemeChange(Brightness systemBrightness) {
    if (useSystemTheme) {
      final shouldBeDark = systemBrightness == Brightness.dark;
      if (_isDarkMode != shouldBeDark) {
        _isDarkMode = shouldBeDark;
        notifyListeners();
      }
    }
  }

  // Force theme refresh
  void refreshTheme() {
    notifyListeners();
  }
}