import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/config/ProtectedRoute.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/ResetPasswordPage.dart';
import 'package:geolab/features/Auth/SignInPage.dart';
import 'package:geolab/features/Auth/SignUpPage.dart';
import 'package:geolab/features/Home/home_screen.dart';
import 'package:geolab/features/Settings/SettingsPage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolab/Service/supabase_service.dart'; // Added for password recovery check
import 'package:geolab/main.dart' show isRecoveryMode, setRecoveryMode;

// Conditional import for web URL cleaning
import 'package:geolab/features/Auth/url_cleaner_stub.dart'
    if (dart.library.html) 'package:geolab/features/Auth/url_cleaner_web.dart' as url_cleaner;

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final uri = state.uri;
      final currentPath = uri.path;
      
      // =================================================================
      // PRIORITY 1: Allow reset-password page immediately - no redirects
      // =================================================================
      if (currentPath == '/reset-password') {
        return null;
      }
      
      // Check if we are in recovery mode (from main.dart)
      // Import: import 'package:geolab/main.dart' as main_app;
      try {
        // Access the global from main.dart
        if (isRecoveryMode) {
          // If in recovery mode, FORCE redirect to reset-password if trying to go to home
          // This prevents the router from falling back to '/' after auth state changes
          if (currentPath == '/') {
            print('🔍 Router: Recovery mode active & path is /, forcing redirect to /reset-password');
            return '/reset-password';
          }
        }
      } catch (e) {
        // Ignore if can't access
      }
      
      
      // =================================================================
      // PRIORITY 2: Redirect to reset-password if we have password reset params
      // =================================================================
      // Check for password reset indicators: code, token, or type=recovery
      final hasCode = uri.queryParameters.containsKey('code');
      final hasToken = uri.queryParameters.containsKey('token');
      final isRecovery = uri.queryParameters['type'] == 'recovery';
      
      if (hasCode || hasToken || isRecovery) {
        // If we have password reset params but we're NOT on reset-password, redirect there
        if (currentPath != '/reset-password') {
          // Preserve all query parameters in the redirect
          final params = uri.queryParameters;
          final queryString = params.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');
          
          return '/reset-password?$queryString';
        }
      }

      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      // Don't redirect if auth is still loading
      if (authState is AuthLoading || authState is AuthInitial) {
        return null;
      }

      // If on auth pages and authenticated, redirect to home
      if (currentPath == '/sign-in' || currentPath == '/sign-up') {
        if (authState is AuthAuthenticated) {
          return '/';
        }
        return null;
      }

      // If on protected pages and not authenticated, redirect to sign-in
      if (currentPath == '/' || currentPath == '/settings' || currentPath == '/profile') {
        if (authState is AuthUnauthenticated) {
          return '/sign-in';
        }
      }

      return null;
    } catch (e) {
      print('🔍 Router: ERROR in redirect function: $e');
      return null;
    }
  },
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];
        final token = state.uri.queryParameters['token'];
        final email = state.uri.queryParameters['email'];
        final type = state.uri.queryParameters['type'];
        
        return ResetPasswordPage(
          code: code ?? token, // Use token as code if code is null (PKCE flow)
          email: email,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const ProtectedRoute(
        child: SettingsPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProtectedRoute(
        child: SettingsPage(), // Profile is part of settings for now
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ProtectedRoute(
      child: HomePage(),
      )
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you are looking for does not exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
