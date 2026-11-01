sealed class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneCountryCode;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? nationality;

  AuthRegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneCountryCode,
    this.phoneNumber,
    this.dateOfBirth,
    this.nationality,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckSessionRequested extends AuthEvent {}

/// User typed the one-time code on the MFA screen.
class AuthMfaVerifyRequested extends AuthEvent {
  final String code;

  AuthMfaVerifyRequested({required this.code});
}

/// User asked for a new one-time code.
class AuthMfaResendRequested extends AuthEvent {}

/// User left the MFA screen without finishing.
class AuthMfaCancelled extends AuthEvent {}
