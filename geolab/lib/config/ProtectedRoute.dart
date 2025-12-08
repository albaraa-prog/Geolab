import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/utils/SplashScreen.dart';
import 'package:go_router/go_router.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/sign-in');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
          if (state is AuthLoading) {
            return const SplashScreen();
          }
          }

          if (state is AuthAuthenticated) {
            return child;
          }

          // If not authenticated, show loading while redirecting
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Redirecting to login...'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
