import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LocalizationConfig {
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
    Locale('fr', 'FR'), // French
    Locale('es', 'ES'), // Spanish
    Locale('de', 'DE'), // German
    Locale('zh', 'CN'), // Chinese
    Locale('ja', 'JP'), // Japanese
    Locale('ko', 'KR'), // Korean
    Locale('pt', 'BR'), // Portuguese
    Locale('ru', 'RU'), // Russian
  ];

  // Default locale
  static const Locale defaultLocale = Locale('en', 'US');

  // Localizations delegates
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // Get locale display name
  static String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  // Get locale flag emoji
  static String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ar':
        return '🇸🇦';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'pt':
        return '🇧🇷';
      case 'ru':
        return '🇷🇺';
      default:
        return '🌐';
    }
  }

  // Check if locale is RTL
  static bool isRTL(Locale locale) {
    return locale.languageCode == 'ar' || 
           locale.languageCode == 'he' || 
           locale.languageCode == 'fa';
  }

  // Get text direction for locale
  static TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  // Get locale from language code
  static Locale getLocaleFromLanguageCode(String languageCode) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => defaultLocale,
    );
  }

  // Get locale from country code
  static Locale getLocaleFromCountryCode(String countryCode) {
    return supportedLocales.firstWhere(
      (locale) => locale.countryCode == countryCode,
      orElse: () => defaultLocale,
    );
  }

  // Get all language codes
  static List<String> get languageCodes {
    return supportedLocales.map((locale) => locale.languageCode).toList();
  }

  // Get all country codes
  static List<String> get countryCodes {
    return supportedLocales
        .where((locale) => locale.countryCode != null)
        .map((locale) => locale.countryCode!)
        .toList();
  }

  // Check if locale is supported
  static bool isLocaleSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode &&
        (supportedLocale.countryCode == null || 
         supportedLocale.countryCode == locale.countryCode),
    );
  }

  // Get fallback locale
  static Locale getFallbackLocale(Locale locale) {
    // Try to find exact match first
    if (isLocaleSupported(locale)) {
      return locale;
    }

    // Try to find language match
    final languageMatch = supportedLocales.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      orElse: () => defaultLocale,
    );

    if (languageMatch != defaultLocale) {
      return languageMatch;
    }

    // Return default locale as fallback
    return defaultLocale;
  }
}
