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
