import 'package:carlton_leisure_app/features/auth/domain/entities/user.dart';

import '../../domain/entities/user.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final int claimedBookingCount;

  AuthAuthenticated({required this.user, this.claimedBookingCount = 0});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}