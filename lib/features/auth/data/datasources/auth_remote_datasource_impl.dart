import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/api/Auth';

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/login',
        data: request.toJson(),
      );
      final user = response.data['user'] as Map<String, dynamic>;
      return LoginResponse(
        user: UserModel.fromJson(user),
        expiresAt: DateTime.parse(response.data['expiresAt'] as String),
        claimedBookingCount: response.data['claimedBookingCount'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LoginResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/register',
        data: request.toJson(),
      );
      final user = response.data['user'] as Map<String, dynamic>;
      return LoginResponse(
        user: UserModel.fromJson(user),
        expiresAt: DateTime.parse(response.data['expiresAt'] as String),
        claimedBookingCount: response.data['claimedBookingCount'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LoginResponse> refreshToken() async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/refresh',
      );
      final user = response.data['user'] as Map<String, dynamic>;
      return LoginResponse(
        user: UserModel.fromJson(user),
        expiresAt: DateTime.parse(response.data['expiresAt'] as String),
        claimedBookingCount: 0,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post<dynamic>('$_basePath/logout');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please check your network.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode == 401) {
          return Exception('Invalid credentials. Please try again.');
        }
        if (statusCode == 409) {
          return Exception(
            data is Map
                ? (data['message'] as String?) ?? 'Account already exists.'
                : 'Account already exists.',
          );
        }
        if (statusCode == 429) {
          return Exception('Too many attempts. Please try again later.');
        }
        final message = data is Map
            ? (data['message'] as String?) ?? 'Something went wrong.'
            : 'Something went wrong.';
        return Exception(message);
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('An unexpected error occurred.');
    }
  }
}