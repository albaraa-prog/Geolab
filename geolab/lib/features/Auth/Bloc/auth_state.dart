import 'package:equatable/equatable.dart';
import 'package:geolab/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthOTPSent extends AuthState {
  final String message;
  final String email;

  const AuthOTPSent({
    required this.message,
    required this.email,
  });

  @override
  List<Object?> get props => [message, email];
}

class AuthOTPVerified extends AuthState {
  final String message;

  const AuthOTPVerified({required this.message});

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}