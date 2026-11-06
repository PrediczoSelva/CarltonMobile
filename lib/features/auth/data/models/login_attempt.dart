import '../../domain/entities/mfa_challenge.dart';
import 'login_response.dart';

/// Raw result of POST /Auth/login: either a finished login or an MFA challenge.
class LoginAttempt {
  const LoginAttempt.success(LoginResponse this.response) : challenge = null;
  const LoginAttempt.mfa(MfaChallenge this.challenge) : response = null;

  final LoginResponse? response;
  final MfaChallenge? challenge;

  bool get requiresMfa => challenge != null;
}
