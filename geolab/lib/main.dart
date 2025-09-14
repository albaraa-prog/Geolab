import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/config/localization_config.dart';
import 'package:geolab/config/router.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/config/theme_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_bloc.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await LocalizationService.instance.loadTranslations();

  runApp(const GeolabApp());
}

class GeolabApp extends StatelessWidget {
  const GeolabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>(
              create: (context) => SettingsBloc(snapshot.data!),
            ),
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                apiService: ApiService(),
              )..add(AuthCheckRequested()),
            ),
            BlocProvider<RockClassificationBloc>(
              create: (context) => RockClassificationBloc(
                apiService: ApiService(),
              ),
            ),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<LocalizationService>(
                create: (context) => LocalizationService.instance,
              ),
              ChangeNotifierProvider<ThemeService>(
                create: (context) => ThemeService.instance,
              ),
            ],
            child: Consumer2<LocalizationService, ThemeService>(
              builder: (context, localizationService, themeService, child) {
                return MaterialApp.router(
                  title: 'Geolab - Rock Classification',
                  debugShowCheckedModeBanner: false,

                  // Theme configuration
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeService.themeMode,

                  // Localization configuration
                  locale: localizationService.currentLocale,
                  supportedLocales: LocalizationConfig.supportedLocales,
                  localizationsDelegates:
                      LocalizationConfig.localizationsDelegates,

                  // Router configuration
                  routerConfig: router,

                  // Web-specific configurations
                  scrollBehavior: kIsWeb ? const MaterialScrollBehavior() : null,

                  // Builder to handle theme changes and responsive design
                  builder: (context, child) {
                    return Theme(
                      data: themeService.currentTheme,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          // Ensure minimum text scale factor for web
                          textScaler: TextScaler.linear(kIsWeb 
                              ? MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2)
                              : MediaQuery.of(context).textScaleFactor),
                        ),
                        child: child!,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
