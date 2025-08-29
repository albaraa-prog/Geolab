import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolab/config/theme.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  static ThemeService get instance {
    _instance ??= ThemeService();
    return _instance!;
  }

  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeService() {
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;
    _isDarkMode = isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Get theme mode for MaterialApp
  ThemeMode get themeMode {
    if (!_isInitialized) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Check if system theme should be used
  bool get useSystemTheme => _prefs.getBool('useSystemTheme') ?? false;

  // Set system theme preference
  Future<void> setUseSystemTheme(bool useSystem) async {
    await _prefs.setBool('useSystemTheme', useSystem);
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

  // Get input decoration theme based on current theme
  InputDecorationTheme get inputDecorationTheme {
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
  AppBarTheme get appBarTheme {
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
}
