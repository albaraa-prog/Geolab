import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ThemeToggled extends SettingsEvent {
  final bool isDarkMode;

  const ThemeToggled({required this.isDarkMode});

  @override
  List<Object> get props => [isDarkMode];
}

class LanguageChanged extends SettingsEvent {
  final String languageCode;

  const LanguageChanged({required this.languageCode});

  @override
  List<Object> get props => [languageCode];
}

class ProfileUpdated extends SettingsEvent {
  final String? userName;
  final String? userEmail;
  final String? avatarPath;

  const ProfileUpdated({
    this.userName,
    this.userEmail,
    this.avatarPath,
  });

  @override
  List<Object> get props => [userName ?? '', userEmail ?? '', avatarPath ?? ''];
}

class NotificationSettingsChanged extends SettingsEvent {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettingsChanged({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  @override
  List<Object> get props => [pushNotifications, emailNotifications, soundEnabled, vibrationEnabled];
}

class PrivacySettingsChanged extends SettingsEvent {
  final bool dataCollection;
  final bool analytics;
  final bool crashReporting;
  final bool personalizedAds;

  const PrivacySettingsChanged({
    required this.dataCollection,
    required this.analytics,
    required this.crashReporting,
    required this.personalizedAds,
  });

  @override
  List<Object> get props => [dataCollection, analytics, crashReporting, personalizedAds];
}

class DataManagementRequested extends SettingsEvent {
  final String action; // 'export', 'delete', 'clear_cache'

  const DataManagementRequested({required this.action});

  @override
  List<Object> get props => [action];
}

class AppSettingsChanged extends SettingsEvent {
  final bool autoSave;
  final bool highQualityImages;
  final bool offlineMode;
  final int maxCacheSize;

  const AppSettingsChanged({
    required this.autoSave,
    required this.highQualityImages,
    required this.offlineMode,
    required this.maxCacheSize,
  });

  @override
  List<Object> get props => [autoSave, highQualityImages, offlineMode, maxCacheSize];
}
