import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';

abstract class AuthRemoteDatasource {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> register(RegisterRequest request);
  Future<LoginResponse> refreshToken();
  Future<void> logout();
}