import 'mfa_challenge.dart';
import 'user.dart';

/// Outcome of the password step of sign-in.
sealed class LoginResult {
  const LoginResult();
}

/// Signed in – no second factor needed.
class LoginSuccess extends LoginResult {
  const LoginSuccess(this.user);
  final UserEntity user;
}

/// Password was correct, but a one-time code must be entered.
class LoginMfaRequired extends LoginResult {
  const LoginMfaRequired(this.challenge);
  final MfaChallenge challenge;
}
