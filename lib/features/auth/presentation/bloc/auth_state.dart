import 'package:carlton_leisure_app/features/auth/domain/entities/user.dart';

import '../../domain/entities/mfa_challenge.dart';
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

/// Password was accepted; waiting for the one-time code.
class AuthMfaRequired extends AuthState {
  final MfaChallenge challenge;

  /// True only for the emission straight after the password step
  /// (the login screen uses it to open the MFA screen once).
  final bool isNewChallenge;

  /// Set when the last verify/resend attempt failed.
  final String? errorMessage;

  /// True right after a new code was sent.
  final bool codeResent;

  AuthMfaRequired({
    required this.challenge,
    this.isNewChallenge = false,
    this.errorMessage,
    this.codeResent = false,
  });
}
