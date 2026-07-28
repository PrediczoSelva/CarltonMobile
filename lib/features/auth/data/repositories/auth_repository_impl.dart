import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource_impl.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required FlutterSecureStorage secureStorage,
  })  : _remoteDatasource = remoteDatasource,
        _secureStorage = secureStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final FlutterSecureStorage _secureStorage;

  static const _keyUser = 'current_user';

  @override
  Future<UserEntity> login(String username, String password) async {
    final response = await _remoteDatasource.login(
      LoginRequest(username: username, password: password),
    );
    await _saveUser(response.user);
    return UserEntity.fromModel(response.user);
  }

  @override
  Future<UserEntity> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneCountryCode,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? nationality,
  }) async {
    final response = await _remoteDatasource.register(
      RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneCountryCode: phoneCountryCode,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        nationality: nationality,
      ),
    );
    await _saveUser(response.user);
    return UserEntity.fromModel(response.user);
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final userJson = await _secureStorage.read(key: _keyUser);
    if (userJson == null) {
      throw Exception('No authenticated user');
    }
    final userMap = Map<String, dynamic>.from(
      const JsonDecoder().convert(userJson) as Map,
    );
    return UserEntity.fromModel(UserModel.fromJson(userMap));
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {
      // Best-effort: clear local state regardless of server response
    } finally {
      await _secureStorage.delete(key: _keyUser);
    }
  }

  @override
  Future<bool> hasActiveSession() async {
    final userJson = await _secureStorage.read(key: _keyUser);
    return userJson != null;
  }

  Future<void> _saveUser(UserModel user) async {
    await _secureStorage.write(
      key: _keyUser,
      value: const JsonEncoder().convert(user.toJson()),
    );
  }
}
