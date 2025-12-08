import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/network_service.dart';
import 'dart:io' as io;
import 'package:geolab/config/app_config.dart';
import 'package:geolab/config/localization_config.dart';
import 'package:geolab/config/router.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_bloc.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolab/Service/supabase_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// Global flag for password recovery redirect
bool _isRecoveryMode = false;
bool get isRecoveryMode => _isRecoveryMode;
void setRecoveryMode(bool value) => _isRecoveryMode = value;

void main() async {
  // Catch global async errors (outside Flutter context)
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global Error Handling for Flutter Framework Errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Note: In production, submit to Crashlytics here
    };

    // Load environment variables from .env file
    bool envLoaded = false;
    try {
      // For Android/iOS, .env needs to be loaded from assets
      // For web/desktop, it can be loaded from root
      try {
        await dotenv.load(fileName: ".env");
        envLoaded = true;
      } catch (e1) {
        try {
          await dotenv.load(fileName: "assets/.env");
          envLoaded = true;
        } catch (e2) {
          try {
            await dotenv.load();
            envLoaded = true;
          } catch (e3) {
            // Silent failure
          }
        }
      }
      
      if (envLoaded) {
        // Validate that keys are loaded
        final url = dotenv.env['SUPABASE_URL'];
        final key = dotenv.env['SUPABASE_ANON_KEY'];
        
        if (url == null || url.isEmpty || url == 'YOUR_SUPABASE_URL') {
          envLoaded = false;
        } 
        
        if (key == null || key.isEmpty || key == 'YOUR_SUPABASE_ANON_KEY') {
          envLoaded = false;
        }
      }
    } catch (e) {
      envLoaded = false;
    }


    // Initialize Supabase - MUST complete before creating services
    try {
      await SupabaseService.initialize();
      
      // Set up auth listener IMMEDIATELY after init to catch PASSWORD_RECOVERY event
      // This MUST happen before runApp() to catch the deep link processing
      SupabaseService.client?.auth.onAuthStateChange.listen((data) {
        // Check for PASSWORD_RECOVERY event - this fires when user clicks reset link
        if (data.event == AuthChangeEvent.passwordRecovery) {
          setRecoveryMode(true);
        }
      });
      
      // Give Supabase a moment to process any deep links and fire events
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      // If Supabase fails to initialize, the app will still run but auth features won't work
    }
  

    // Initialize services
    await LocalizationService.instance.loadTranslations();
    
    // Initialize network service
    await NetworkService().initialize();

    runApp(const GeolabApp());
  }, (error, stack) {
    // Catch global async errors
  });
}

class GeolabApp extends StatelessWidget {
  const GeolabApp({super.key});

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
            // Check auth state on startup
            bloc.add(AuthCheckRequested());
            
            // Listen to Supabase auth changes and sync with BLoC
            // Note: PASSWORD_RECOVERY is handled in main() before runApp()
            if (SupabaseService.isInitialized) {
              SupabaseService.client?.auth.onAuthStateChange.listen((data) {
                final AuthChangeEvent event = data.event;
                
                // PASSWORD_RECOVERY is already handled in main(), skip it here
                if (event == AuthChangeEvent.passwordRecovery) {
                  return;
                }
                
                // Check current bloc state to prevent infinite loops
                final currentState = bloc.state;
                final isAlreadyUnauthenticated = currentState is AuthUnauthenticated;
                final isCurrentlyLoggingOut = currentState is AuthLoading;
                
                // Don't trigger navigation if we're on reset-password page
                // (user needs to set new password first)
                final currentPath = Uri.base.path;
                if (currentPath == '/reset-password') {
                  // Still update auth state, but don't navigate away
                  if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
                    bloc.add(AuthCheckRequested());
                  } else if (event == AuthChangeEvent.signedOut && !isAlreadyUnauthenticated && !isCurrentlyLoggingOut) {
                    bloc.add(AuthLogoutRequested());
                  }
                  return; // Don't navigate away from reset-password page
                }
                
                if (event == AuthChangeEvent.signedIn) {
                  // User signed in via magic link or password
                  bloc.add(AuthCheckRequested());
                } else if (event == AuthChangeEvent.signedOut) {
                  // Only dispatch logout if we're not already unauthenticated or logging out
                  if (!isAlreadyUnauthenticated && !isCurrentlyLoggingOut) {
                    bloc.add(AuthLogoutRequested());
                  }
                } else if (event == AuthChangeEvent.userUpdated) {
                  // User metadata updated
                  bloc.add(AuthCheckRequested());
                }
              });
            }
            
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
              themeMode: themeService.useSystemTheme ? ThemeMode.system : themeService.themeMode,

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
                // Handle system theme changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  themeService.handleSystemThemeChange(
                    MediaQuery.of(context).platformBrightness,
                  );
                });
                
                return BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    // Don't refresh router if we're on reset-password page
                    // This prevents unwanted redirects during password recovery
                    final currentRoute = router.routerDelegate.currentConfiguration.uri.path;
                    if (currentRoute == '/reset-password') {
                      return;
                    }
                    
                    // Force router to re-evaluate redirects on auth state change
                    router.refresh();
                  },
                  child: Theme(
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
