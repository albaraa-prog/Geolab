import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/supabase_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  // ignore: unused_field
  StreamSubscription<dynamic>? _authStateSubscription;

  AuthBloc({required ApiService apiService})
      : _apiService = apiService,
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSendEmailVerificationRequested>(_onSendEmailVerificationRequested);
    on<AuthResendEmailVerificationRequested>(_onResendEmailVerificationRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    
    _initializeAuthStateListener();
  }

  void _initializeAuthStateListener() {
    try {
      if (SupabaseService.isInitialized) {
        _authStateSubscription = SupabaseService.authStateChanges.listen((data) {
          // When auth state changes (e.g. email verified, logged in via link), check auth
          add(AuthCheckRequested());
        });
      }
    } catch (e) {
      // Supabase might not be initialized yet, which is fine
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.loginWithPassword(
        email: event.email,
        password: event.password,
      );

      // Get the full user model from Supabase
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        // Fallback to creating user model from response
        final userFromResponse = UserModel.fromJson(response['user']);
        emit(AuthAuthenticated(user: userFromResponse));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Use Supabase signUpWithPassword
      // Supabase will throw an error if email already exists
      final authResponse = await SupabaseService.signUpWithPassword(
        email: event.email,
        password: event.password,
        data: {
          'subscription_tier': event.subscriptionTier,
        },
      );
      
      if (authResponse.user != null) {
        // Get the full user model from Supabase
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          // Fallback
          final userFromResponse = UserModel(
            id: authResponse.user!.id,
            email: authResponse.user!.email ?? '',
            subscriptionTier: event.subscriptionTier,
            requestCount: 0,
            dailyLimit: 5,
            createdAt: DateTime.now(),
          );
          emit(AuthAuthenticated(user: userFromResponse));
        }
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      // Check for specific error types
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('already') || 
          errorMessage.contains('exists') || 
          errorMessage.contains('registered') ||
          errorMessage.contains('duplicate') ||
          errorMessage.contains('user_already_exists')) {
        emit(AuthError(message: 'An account with this email already exists. Please sign in instead.'));
      } else if (errorMessage.contains('email')) {
        emit(AuthError(message: 'Invalid email address. Please check and try again.'));
      } else if (errorMessage.contains('password')) {
        emit(AuthError(message: 'Password is too weak. Please use a stronger password.'));
      } else {
        emit(AuthError(message: 'Registration failed: ${e.toString()}'));
      }
    }
  }

  Future<void> _onSendEmailVerificationRequested(
    AuthSendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // If this is a signup with name and password
      if (event.name.isNotEmpty && event.password.isNotEmpty) {
        // Try to sign up - Supabase will automatically prevent duplicates
        final authResponse = await SupabaseService.signUpWithPassword(
          email: event.email,
          password: event.password,
          data: {
            'name': event.name,
            'full_name': event.name,
            'subscription_tier': 'free',
          },
        );
        
        // If signup successful, send verification email
        if (authResponse.user != null) {
          await _apiService.sendEmailVerification(
            email: event.email,
            name: event.name,
            password: event.password,
          );
          emit(AuthEmailVerificationSent(
            message: 'Verification email sent successfully. Please check your inbox.',
            email: event.email,
          ));
        } else {
          throw Exception('Failed to create account');
        }
      } else {
        // Just send verification email for sign-in
        await _apiService.sendEmailVerification(
          email: event.email,
          name: event.name,
          password: event.password,
        );
        emit(AuthEmailVerificationSent(
          message: 'Verification email sent successfully. Please check your inbox.',
          email: event.email,
        ));
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      // Supabase returns specific errors for duplicate emails
      if (errorMessage.contains('user already registered') ||
          errorMessage.contains('already been registered') ||
          errorMessage.contains('email already') ||
          errorMessage.contains('duplicate')) {
        emit(AuthError(message: 'An account with this email already exists. Please sign in instead.'));
      } else if (errorMessage.contains('email') && errorMessage.contains('taken')) {
        emit(AuthError(message: 'An account with this email already exists. Please sign in instead.'));
      } else {
        emit(AuthError(message: e.toString()));
      }
    }
  }

  Future<void> _onResendEmailVerificationRequested(
    AuthResendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Resend email verification link via Supabase
      await _apiService.sendEmailVerification(
        email: event.email,
      );
      emit(AuthEmailVerificationSent(
        message: 'Verification email resent successfully. Please check your inbox.',
        email: event.email,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _apiService.resetPassword(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if already unauthenticated to prevent unnecessary logout calls
    final currentState = state;
    if (currentState is AuthUnauthenticated) {
      return; // Already logged out, don't call logout again
    }
    
    emit(AuthLoading());
    try {
      await _apiService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, we should still show unauthenticated state
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isAuthenticated = await _apiService.isAuthenticated();
      if (isAuthenticated) {
        try {
          final user = await _apiService.getCurrentUser();
          if (user != null) {
            emit(AuthAuthenticated(user: user));
          } else {
            emit(AuthUnauthenticated());
          }
        } catch (e) {
          // If Supabase not initialized, just show unauthenticated
          if (e.toString().contains('not been initialized')) {
            emit(AuthUnauthenticated());
          } else {
            rethrow;
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Silently handle errors - just show unauthenticated state
      emit(AuthUnauthenticated());
    }
  }
}