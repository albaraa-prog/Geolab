import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
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
    on<AuthSendOTPRequested>(_onSendOTPRequested);
    on<AuthResendOTPRequested>(_onResendOTPRequested);
    on<AuthVerifyOTPAndRegister>(_onVerifyOTPAndRegister);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(
        email: event.email,
        password: event.password,
      );

      final user = UserModel.fromJson(response['user']);
      emit(AuthAuthenticated(user: user));
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
      final response = await _apiService.register(
        email: event.email,
        password: event.password,
        subscriptionTier: event.subscriptionTier,
      );

      final user = UserModel.fromJson(response['user']);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSendOTPRequested(
    AuthSendOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.sendSignupOTP(email: event.email);
      emit(AuthOTPSent(
        message: response['message'] ?? 'OTP sent successfully',
        email: event.email,
        otpCode: response['otp_code'], // Include OTP for testing
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onResendOTPRequested(
    AuthResendOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.sendSignupOTP(email: event.email);
      emit(AuthOTPSent(
        message: response['message'] ?? 'OTP resent successfully',
        email: event.email,
        otpCode: response['otp_code'], // Include OTP for testing
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOTPAndRegister(
    AuthVerifyOTPAndRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.verifyOTPAndRegister(
        email: event.email,
        name: event.name,
        password: event.password,
        otp: event.otp,
        subscriptionTier: event.subscriptionTier,
      );
      
      final user = UserModel.fromJson(response['user']);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
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
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}