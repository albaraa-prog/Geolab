import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/supabase_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

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
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSendEmailVerificationRequested(
    AuthSendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // If this is a signup with name and password, sign up first then send verification
      if (event.name.isNotEmpty && event.password.isNotEmpty) {
        // Sign up with password first to create the account
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
      emit(AuthError(message: e.toString()));
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