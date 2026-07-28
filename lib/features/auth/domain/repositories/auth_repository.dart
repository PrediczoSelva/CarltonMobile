import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String username, String password);
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