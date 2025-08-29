import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_event.dart';
import 'package:geolab/features/Settings/bloc/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _prefs;

  SettingsBloc(this._prefs)
      : super(SettingsState(
          isDarkMode: _prefs.getBool('isDarkMode') ?? false,
          languageCode: _prefs.getString('languageCode') ?? 'en',
        )) {
    on<ThemeToggled>(_onThemeToggled);
    on<LanguageChanged>(_onLanguageChanged);
  }

  void _onThemeToggled(ThemeToggled event, Emitter<SettingsState> emit) {
    _prefs.setBool('isDarkMode', event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }

  void _onLanguageChanged(LanguageChanged event, Emitter<SettingsState> emit) {
    _prefs.setString('languageCode', event.languageCode);
    emit(state.copyWith(languageCode: event.languageCode));
  }
}
