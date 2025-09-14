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

class AuthSendOTPRequested extends AuthEvent {
  final String email;

  const AuthSendOTPRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResendOTPRequested extends AuthEvent {
  final String email;

  const AuthResendOTPRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOTPAndRegister extends AuthEvent {
  final String email;
  final String name;
  final String password;
  final String otp;
  final String subscriptionTier;

  const AuthVerifyOTPAndRegister({
    required this.email,
    required this.name,
    required this.password,
    required this.otp,
    required this.subscriptionTier,
  });

  @override
  List<Object?> get props => [email, name, password, otp, subscriptionTier];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}