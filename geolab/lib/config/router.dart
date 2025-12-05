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

// Conditional import for web URL cleaning
import 'package:geolab/features/Auth/url_cleaner_stub.dart'
    if (dart.library.html) 'package:geolab/features/Auth/url_cleaner_web.dart' as url_cleaner;

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final uri = state.uri;
      final currentPath = uri.path;
      
      // Always allow access to reset-password page (even with code parameter or hash fragments)
      // This allows the page to handle the password reset code
      // Ignore any hash fragments when on reset-password page
      if (currentPath == '/reset-password') {
        // Clean URL hash fragment immediately in redirect (before any routing happens)
        // This prevents the hash fragment from being processed by the router or browser
        // Clean regardless of whether we detect fragment in URI, as it might be added later
        if (kIsWeb) {
          url_cleaner.cleanResetPasswordUrl();
          // Clean again after a microtask to catch any async additions
          Future.microtask(() {
            url_cleaner.cleanResetPasswordUrl();
          });
        }
        // Don't redirect - let the page handle it, ignore hash fragments
        // Also prevent auth-based redirects when we have a reset code
        // Allow access even without code parameter - the page will handle validation
        return null;
      }
      
      // Check for Supabase callback code in query parameters
      if (uri.queryParameters.containsKey('code')) {
        // Check if this is a password reset (reset-password path) or magic link
        // For magic link sign-in, let Supabase process the code first
        // The auth state listener will handle navigation after authentication
        // Don't redirect here to avoid go_router assertion errors
        if (currentPath != '/reset-password') {
          return null;
        }
      }
      
      // Handle hash fragments for web deep links (without code)
      // Only process hash fragments if we're NOT on reset-password page AND no code parameter
      if (uri.hasFragment && uri.fragment.isNotEmpty && 
          !uri.queryParameters.containsKey('code') && 
          currentPath != '/reset-password') {
        final fragment = uri.fragment.replaceFirst('#', '');
        if (fragment.startsWith('/')) {
          final cleanFragment = fragment.split('?').first;
          // Don't redirect to hash fragment if we're on reset-password
          if (cleanFragment.isNotEmpty && cleanFragment != currentPath) {
            return cleanFragment;
          }
        }
      }

      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      // Don't redirect if auth is still loading or initial
      if (authState is AuthLoading || authState is AuthInitial) {
        return null;
      }

      // If we're on auth pages and user is authenticated, redirect to home
      if (currentPath == '/sign-in' || currentPath == '/sign-up') {
        if (authState is AuthAuthenticated) {
          return '/';
        }
        return null; // Allow access to auth pages if not authenticated
      }

      // If we're on protected pages and user is not authenticated, redirect to sign-in
      if (currentPath == '/' ||
          currentPath == '/settings' ||
          currentPath == '/profile') {
        if (authState is AuthUnauthenticated) {
          return '/sign-in';
        }
      }

      return null;
    } catch (e) {
      // If there's an error reading auth state, allow navigation to continue
      // This prevents crashes during initial app load
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
        final uri = state.uri;
        
        // Clean URL hash fragment immediately if present (before building the page)
        // This prevents the hash fragment from being processed by the router
        if (uri.hasFragment && kIsWeb) {
          // Clean URL immediately in router builder to prevent hash fragment redirects
          url_cleaner.cleanResetPasswordUrl();
        }
        
        // Get code and email from URI
        var code = uri.queryParameters['code'];
        final email = uri.queryParameters['email'];
        
        // Clean code parameter if it contains path fragments (malformed URL)
        // This can happen if the hash fragment gets appended to the code parameter
        if (code != null && code.contains('/')) {
          // Extract just the code part (before any path fragments)
          code = code.split('/').first;
        }
        
        // Allow the page to load even without code - it will handle validation
        // This is important because Supabase might redirect without code initially,
        // or the code might be processed asynchronously
        // The ResetPasswordPage will validate and show appropriate error if code is missing
        
        return ResetPasswordPage(
          code: code,
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
