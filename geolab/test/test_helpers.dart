import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:geolab/config/router.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/config/localization_config.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_bloc.dart';
import 'package:geolab/features/Settings/components/localization.dart';

// Note: We use .value instead of create to prevent Provider from disposing
// singleton instances between tests. This is safe for singletons.
// We also ensure services are initialized before use.

/// Ensures services are initialized for testing
Future<void> setupTestServices() async {
  // Ensure LocalizationService is initialized
  final localizationService = LocalizationService.instance;
  if (!localizationService.isInitialized) {
    await localizationService.loadTranslations();
  }
  // ThemeService doesn't need async initialization
}

/// Test helper widget that sets up all required providers for router testing
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            final bloc = AuthBloc(apiService: ApiService());
            // Don't check auth state in tests to avoid async issues
            return bloc;
          },
        ),
        BlocProvider<RockClassificationBloc>(
          create: (context) => RockClassificationBloc(
            apiService: ApiService(),
          ),
        ),
      ],
      child: MultiProvider(
        providers: [
          // Use .value to prevent Provider from disposing singleton instances
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService.instance,
          ),
          ChangeNotifierProvider<ThemeService>.value(
            value: ThemeService.instance,
          ),
        ],
        child: Consumer2<LocalizationService, ThemeService>(
          builder: (context, localizationService, themeService, child) {
            return MaterialApp.router(
              title: 'Geolab Test',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeService.themeMode,
              locale: localizationService.currentLocale,
              supportedLocales: LocalizationConfig.supportedLocales,
              localizationsDelegates: LocalizationConfig.localizationsDelegates,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

/// Test helper widget that wraps a widget with all required providers for widget testing
class TestWidgetWrapper extends StatelessWidget {
  final Widget child;

  const TestWidgetWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(apiService: ApiService()),
        ),
        BlocProvider<RockClassificationBloc>(
          create: (context) => RockClassificationBloc(
            apiService: ApiService(),
          ),
        ),
      ],
      child: MultiProvider(
        providers: [
          // Use .value to prevent Provider from disposing singleton instances
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService.instance,
          ),
          ChangeNotifierProvider<ThemeService>.value(
            value: ThemeService.instance,
          ),
        ],
        child: Consumer2<LocalizationService, ThemeService>(
          builder: (context, localizationService, themeService, child) {
            return MaterialApp(
              title: 'Geolab Test',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeService.themeMode,
              locale: localizationService.currentLocale,
              supportedLocales: LocalizationConfig.supportedLocales,
              localizationsDelegates: LocalizationConfig.localizationsDelegates,
              home: this.child,
            );
          },
        ),
      ),
    );
  }
}

