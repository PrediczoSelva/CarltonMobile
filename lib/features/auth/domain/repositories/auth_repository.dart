import '../entities/login_result.dart';
import '../entities/mfa_challenge.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<LoginResult> login(String username, String password);
  Future<UserEntity> verifyMfa(MfaChallenge challenge, String code);
  Future<UserEntity> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneCountryCode,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? nationality,
  });
  Future<UserEntity> getCurrentUser();
  Future<void> logout();
  Future<bool> hasActiveSession();
}