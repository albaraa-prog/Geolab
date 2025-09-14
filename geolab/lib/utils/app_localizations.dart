import 'package:flutter/material.dart';
import 'package:geolab/features/Settings/components/localization.dart';

/// Utility class for easy translation access throughout the app
class AppLocalizations {
  static LocalizationService get _service => LocalizationService.instance;

  /// Get current locale
  static Locale get currentLocale => _service.currentLocale;

  /// Check if current locale is RTL
  static bool get isRTL => _service.isRTL;

  /// Get current text direction
  static TextDirection get textDirection => _service.textDirection;

  /// Translate a key
  static String t(String key) => _service.translate(key);

  /// Translate with parameters
  static String tWithParams(String key, Map<String, String> params) =>
      _service.translateWithParams(key, params);

  /// Translate plural
  static String tPlural(String key, int count) =>
      _service.translatePlural(key, count);

  /// Get locale display name
  static String getLocaleDisplayName(Locale locale) =>
      _service.getLocaleDisplayName(locale);

  /// Get locale flag
  static String getLocaleFlag(Locale locale) => _service.getLocaleFlag(locale);

  /// Get available languages
  static List<Map<String, String>> get availableLanguages =>
      _service.availableLanguages;

  /// Check if a key exists
  static bool hasKey(String key) => _service.hasKey(key);

  /// Reload translations
  static Future<void> reloadTranslations() => _service.reloadTranslations();

  /// Set locale
  static Future<void> setLocale(Locale locale) => _service.setLocale(locale);

  /// Set language code
  static Future<void> setLanguageCode(String languageCode) =>
      _service.setLanguageCode(languageCode);
}

/// Extension for BuildContext to easily access translations

extension LocalizationExtension on BuildContext {
  /// Get translation for a key
  String t(String key, [Map<String, String>? params]) {
    if (params != null) {
      return AppLocalizations.tWithParams(key, params);
    }
    return AppLocalizations.t(key);
  }

  /// Get translation with parameters
  String tWithParams(String key, Map<String, String> params) =>
      AppLocalizations.tWithParams(key, params);

  /// Get plural translation
  String tPlural(String key, int count) => AppLocalizations.tPlural(key, count);

  /// Check if current locale is RTL
  bool get isRTL => AppLocalizations.isRTL;

  /// Get current text direction
  TextDirection get textDirection => AppLocalizations.textDirection;

  /// Get current locale
  Locale get currentLocale => AppLocalizations.currentLocale;
}

/// Common translation keys for easy access
class AppKeys {
  // App
  static const String appTitle = 'app.title';
  static const String appSettings = 'app.settings';
  static const String appTheme = 'app.theme';
  static const String appLanguage = 'app.language';
  static const String appDarkMode = 'app.darkMode';
  static const String appLightMode = 'app.lightMode';

  // Settings
  static const String settingsProfileTitle = 'settings.profile.title';
  static const String settingsProfileSubtitle = 'settings.profile.subtitle';
  static const String settingsThemeTitle = 'settings.theme.title';
  static const String settingsThemeMode = 'settings.theme.mode';
  static const String settingsThemeDarkMode = 'settings.theme.darkMode';
  static const String settingsThemeLightMode = 'settings.theme.lightMode';
  static const String settingsThemeSystem = 'settings.theme.system';
  static const String settingsThemeSystemDescription =
      'settings.theme.systemDescription';
  static const String settingsLanguageTitle = 'settings.language.title';
  static const String settingsLanguageCurrent = 'settings.language.current';
  static const String settingsLanguageSelect = 'settings.language.select';
  static const String settingsLanguageRTL = 'settings.language.rtl';
  static const String settingsLanguageRTLDescription =
      'settings.language.rtlDescription';
  static const String settingsAppearanceTitle = 'settings.appearance.title';
  static const String settingsAppearanceColors = 'settings.appearance.colors';
  static const String settingsAppearanceColorsDescription =
      'settings.appearance.colorsDescription';
  static const String settingsAppearanceTypography =
      'settings.appearance.typography';
  static const String settingsAppearanceTypographyDescription =
      'settings.appearance.typographyDescription';
  static const String settingsAppearanceColorsComingSoon =
      'settings.appearance.colorsComingSoon';
  static const String settingsAppearanceTypographyComingSoon =
      'settings.appearance.typographyComingSoon';
  static const String settingsAboutTitle = 'settings.about.title';
  static const String settingsAboutVersion = 'settings.about.version';
  static const String settingsAboutLicense = 'settings.about.license';
  static const String settingsAboutLicenseText = 'settings.about.licenseText';

  // Camera
  static const String cameraPositionRock = 'camera.positionRock';
  static const String cameraCapture = 'camera.capture';
  static const String cameraGallery = 'camera.gallery';
  static const String cameraFlipCamera = 'camera.flipCamera';
  static const String cameraRemove = 'camera.remove';
  static const String cameraSave = 'camera.save';
  static const String cameraSaved = 'camera.saved';
  static const String cameraError = 'camera.error';

  // Auth
  static const String authSignIn = 'auth.signIn';
  static const String authSignUp = 'auth.signUp';
  static const String authEmail = 'auth.email';
  static const String authPassword = 'auth.password';
  static const String authName = 'auth.name';
  static const String authConfirmPassword = 'auth.confirmPassword';
  static const String authNoAccount = 'auth.noAccount';
  static const String authHasAccount = 'auth.hasAccount';
  static const String authForgotPassword = 'auth.forgotPassword';
  static const String authResetPasswordTitle = 'auth.resetPassword.title';
  static const String authResetPasswordDescription =
      'auth.resetPassword.description';
  static const String authResetPasswordCancel = 'auth.resetPassword.cancel';
  static const String authResetPasswordSendLink = 'auth.resetPassword.sendLink';
  static const String authResetPasswordSuccess = 'auth.resetPassword.success';
  static const String authErrorInvalidCredentials =
      'auth.error.invalidCredentials';
  static const String authErrorNetworkError = 'auth.error.networkError';
  static const String authErrorUnknown = 'auth.error.unknown';

  // Common
  static const String commonOk = 'common.ok';
  static const String commonCancel = 'common.cancel';
  static const String commonSave = 'common.save';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
  static const String commonLoading = 'common.loading';
  static const String commonError = 'common.error';
  static const String commonSuccess = 'common.success';
  static const String commonWarning = 'common.warning';
  static const String commonInfo = 'common.info';

  // Navigation
  static const String navigationHome = 'navigation.home';
  static const String navigationCamera = 'navigation.camera';
  static const String navigationGallery = 'navigation.gallery';
  static const String navigationHistory = 'navigation.history';
  static const String navigationSettings = 'navigation.settings';
  static const String navigationProfile = 'navigation.profile';

  // Rock Classification
  static const String rockClassificationTitle = 'rockClassification.title';
  static const String rockClassificationAnalyzing =
      'rockClassification.analyzing';
  static const String rockClassificationResult = 'rockClassification.result';
  static const String rockClassificationConfidence =
      'rockClassification.confidence';
  static const String rockClassificationDescription =
      'rockClassification.description';
  static const String rockClassificationProperties =
      'rockClassification.properties';
  static const String rockClassificationMineralComposition =
      'rockClassification.mineralComposition';
  static const String rockClassificationTexture = 'rockClassification.texture';
  static const String rockClassificationColor = 'rockClassification.color';
  static const String rockClassificationHardness =
      'rockClassification.hardness';
  static const String rockClassificationDensity = 'rockClassification.density';

  // Feedback
  static const String feedbackTitle = 'feedback.title';
  static const String feedbackRateAccuracy = 'feedback.rateAccuracy';
  static const String feedbackSubmitFeedback = 'feedback.submitFeedback';
  static const String feedbackFeedbackSubmitted = 'feedback.feedbackSubmitted';
  static const String feedbackImproveModel = 'feedback.improveModel';
}
