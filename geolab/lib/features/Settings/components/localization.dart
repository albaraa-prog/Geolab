import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolab/config/localization_config.dart';

class LocalizationService extends ChangeNotifier {
  static LocalizationService? _instance;
  static LocalizationService get instance {
    _instance ??= LocalizationService();
    return _instance!;
  }

  Locale _currentLocale = LocalizationConfig.defaultLocale;
  Map<String, dynamic> _translations = {};
  bool _isInitialized = false;
  late SharedPreferences _prefs;

  Locale get currentLocale => _currentLocale;
  Map<String, dynamic> get translations => _translations;
  bool get isInitialized => _isInitialized;
  bool get isRTL => LocalizationConfig.isRTL(_currentLocale);
  TextDirection get textDirection => LocalizationConfig.getTextDirection(_currentLocale);

  LocalizationService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = _prefs.getString('languageCode') ?? 'en';
    final savedCountryCode = _prefs.getString('countryCode');
    
    if (savedCountryCode != null) {
      _currentLocale = Locale(savedLanguageCode, savedCountryCode);
    } else {
      _currentLocale = Locale(savedLanguageCode);
    }

    // Ensure the locale is supported
    _currentLocale = LocalizationConfig.getFallbackLocale(_currentLocale);
    
    await _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/${_currentLocale.languageCode}.json',
      );
      _translations = json.decode(jsonString);
      _isInitialized = true;
      notifyListeners();
      print('Translations loaded successfully for ${_currentLocale.languageCode}');
    } catch (e) {
      // If loading fails, try to load English as fallback
      try {
        final String fallbackJsonString = await rootBundle.loadString(
          'assets/translations/en.json',
        );
        _translations = json.decode(fallbackJsonString);
        print('Fallback translations loaded for English');
      } catch (fallbackError) {
        print('Failed to load fallback translations: $fallbackError');
        _translations = {};
      }
      _isInitialized = true;
      notifyListeners();
      print('Failed to load translations for ${_currentLocale.languageCode}: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    
    // Ensure the locale is supported
    final supportedLocale = LocalizationConfig.getFallbackLocale(locale);
    
    _currentLocale = supportedLocale;
    _isInitialized = false;
    
    // Save to preferences
    await _prefs.setString('languageCode', supportedLocale.languageCode);
    if (supportedLocale.countryCode != null) {
      await _prefs.setString('countryCode', supportedLocale.countryCode!);
    } else {
      await _prefs.remove('countryCode');
    }
    
    notifyListeners();
    await _loadTranslations();
  }

  Future<void> setLanguageCode(String languageCode) async {
    final newLocale = LocalizationConfig.getLocaleFromLanguageCode(languageCode);
    await setLocale(newLocale);
  }

  String translate(String key) {
    if (!_isInitialized) {
      // Return a simple fallback while translations are loading
      return key.split('.').last;
    }

    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        // If not found, return the key itself
        print('Translation key not found: $key');
        return key;
      }
    }

    return value.toString();
  }

  // Helper method to get available locales
  List<Locale> get supportedLocales => LocalizationConfig.supportedLocales;

  // Helper method to get locale display name
  String getLocaleDisplayName(Locale locale) {
    return LocalizationConfig.getLocaleDisplayName(locale);
  }

  // Helper method to get locale flag
  String getLocaleFlag(Locale locale) {
    return LocalizationConfig.getLocaleFlag(locale);
  }

  // Helper method to check if a key exists
  bool hasKey(String key) {
    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return false;
      }
    }

    return true;
  }

  // Get all available language codes with display names
  List<Map<String, String>> get availableLanguages {
    return supportedLocales.map((locale) {
      return {
        'code': locale.languageCode,
        'countryCode': locale.countryCode ?? '',
        'name': getLocaleDisplayName(locale),
        'flag': getLocaleFlag(locale),
      };
    }).toList();
  }

  // Check if current locale is RTL
  bool get isCurrentLocaleRTL => LocalizationConfig.isRTL(_currentLocale);

  // Get current text direction
  TextDirection get currentTextDirection => LocalizationConfig.getTextDirection(_currentLocale);

  // Reload translations (useful for hot reload during development)
  Future<void> reloadTranslations() async {
    _isInitialized = false;
    notifyListeners();
    await _loadTranslations();
  }

  // Get translation with parameters
  String translateWithParams(String key, Map<String, String> params) {
    String translation = translate(key);
    
    params.forEach((paramKey, paramValue) {
      translation = translation.replaceAll('{$paramKey}', paramValue);
    });
    
    return translation;
  }

  // Get plural translation
  String translatePlural(String key, int count) {
    if (count == 0) {
      return translate('$key.zero') ?? translate(key);
    } else if (count == 1) {
      return translate('$key.one') ?? translate(key);
    } else {
      return translate('$key.many') ?? translate(key);
    }
  }

  Future<void> loadTranslations() async {
    await _loadTranslations();
  }
}
