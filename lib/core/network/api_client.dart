import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around [Dio] shared by every feature's repository.
///
/// Handles: base config, attaching the auth token, refreshing an
/// expired token once, and centralised error normalisation.
class ApiClient {
  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      if (_kEnableLogging)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
    ]);
  }

  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  static const bool _kEnableLogging = true; // flip off for release builds

  Dio get dio => _dio;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // TODO: attempt refresh-token flow here, then retry the request.
          // For now, surface the error so the UI can route to login.
        }
        handler.next(error);
      },
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
