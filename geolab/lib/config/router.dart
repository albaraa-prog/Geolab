import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/config/ProtectedRoute.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/SignInPage.dart';
import 'package:geolab/features/Auth/SignUpPage.dart';
import 'package:geolab/features/Auth/otp_test_page.dart';
import 'package:geolab/features/Home/home_screen.dart';
import 'package:geolab/features/Settings/SettingsPage.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    // If we're on auth pages and user is authenticated, redirect to home
    if (state.matchedLocation == '/sign-in' ||
        state.matchedLocation == '/sign-up') {
      if (authState is AuthAuthenticated) {
        return '/';
      }
    }

    // If we're on protected pages and user is not authenticated, redirect to sign-in
    if (state.matchedLocation == '/' ||
        state.matchedLocation == '/settings' ||
        state.matchedLocation == '/profile') {
      if (authState is AuthUnauthenticated) {
        return '/sign-in';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const OTPTestPage(), //const SignInPage(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpPage(),
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
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
