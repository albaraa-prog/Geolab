import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_event.dart';
import 'package:geolab/features/Settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
      : super(SettingsState(
          isDarkMode: false, // Default to light mode
          languageCode: 'en', // Default to English
        )) {
    on<ThemeToggled>(_onThemeToggled);
    on<LanguageChanged>(_onLanguageChanged);
  }

  void _onThemeToggled(ThemeToggled event, Emitter<SettingsState> emit) {
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }

  void _onLanguageChanged(LanguageChanged event, Emitter<SettingsState> emit) {
    emit(state.copyWith(languageCode: event.languageCode));
  }
}
