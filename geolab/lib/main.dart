import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/network_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  bool envLoaded = false;
  try {
    // For Android/iOS, .env needs to be loaded from assets
    // For web/desktop, it can be loaded from root
    try {
      await dotenv.load(fileName: ".env");
      print('✓ .env file loaded from root directory');
      envLoaded = true;
    } catch (e1) {
      print('⚠ Could not load .env from root: $e1');
      try {
        // Try loading from assets (for mobile platforms)
        await dotenv.load(fileName: "assets/.env");
        print('✓ .env file loaded from assets');
        envLoaded = true;
      } catch (e2) {
        print('⚠ Could not load .env from assets: $e2');
        // Last attempt - try without path prefix
        try {
          await dotenv.load();
          print('✓ .env file loaded (default location)');
          envLoaded = true;
        } catch (e3) {
          print('❌ Could not load .env from any location: $e3');
        }
      }
    }
    
    if (envLoaded) {
      // Validate that keys are loaded
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url == null || url.isEmpty || url == 'YOUR_SUPABASE_URL') {
        print('⚠ WARNING: SUPABASE_URL is not set in .env file');
        print('   Current value: ${url ?? "null"}');
        envLoaded = false;
      } else {
        print('✓ SUPABASE_URL loaded: ${url.substring(0, url.length > 30 ? 30 : url.length)}...');
      }
      
      if (key == null || key.isEmpty || key == 'YOUR_SUPABASE_ANON_KEY') {
        print('⚠ WARNING: SUPABASE_ANON_KEY is not set in .env file');
        print('   Current value: ${key != null && key.length > 20 ? "${key.substring(0, 20)}..." : key ?? "null"}');
        envLoaded = false;
      } else {
        print('✓ SUPABASE_ANON_KEY loaded: ${key.substring(0, key.length > 20 ? 20 : key.length)}...');
      }
    }
  } catch (e) {
    print('❌ ERROR: Could not load .env file: $e');
    envLoaded = false;
  }
  
  if (!envLoaded) {
    print('');
    print('⚠ WARNING: .env file could not be loaded properly.');
    print('Please make sure:');
    print('1. The .env file exists in geolab/.env');
    print('2. The .env file is listed in pubspec.yaml assets (it should be)');
    print('3. Run "flutter clean && flutter pub get" after creating/modifying .env');
    print('4. Restart the app completely');
    print('');
  }

  // Initialize Supabase - MUST complete before creating services
  bool supabaseInitialized = false;
  try {
    await SupabaseService.initialize();
    supabaseInitialized = true;
    print('✓ Supabase initialized successfully');
    
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
    print('❌ ERROR initializing Supabase: $e');
    print('');
    print('Common issues:');
    print('1. .env file is missing or in wrong location (should be in geolab/.env)');
    print('2. SUPABASE_URL or SUPABASE_ANON_KEY are incorrect');
    print('3. Check your Supabase project settings at https://app.supabase.com');
    print('');
    // If Supabase fails to initialize, the app will still run but auth features won't work
    // This allows the app to start and show error messages to the user
  }
  
  if (!supabaseInitialized) {
    print('⚠ WARNING: App is running without Supabase. Authentication features will not work.');
  }

  // Initialize services
  await LocalizationService.instance.loadTranslations();
  
  // Initialize network service
  await NetworkService().initialize();

  runApp(const GeolabApp());
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
