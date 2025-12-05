import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String subscriptionTier;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.subscriptionTier = 'free',
  });

  @override
  List<Object?> get props => [email, password, subscriptionTier];
}

class AuthSendEmailVerificationRequested extends AuthEvent {
  final String email;
  final String name;
  final String password;

  const AuthSendEmailVerificationRequested({
    required this.email,
    required this.name,
    required this.password,
  });

  @override
  List<Object?> get props => [email, name, password];
}

class AuthResendEmailVerificationRequested extends AuthEvent {
  final String email;

  const AuthResendEmailVerificationRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}