import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final String languageCode;

  const SettingsState({
    this.isDarkMode = false,
    this.languageCode = 'en',
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? languageCode,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object> get props => [isDarkMode, languageCode];
}
