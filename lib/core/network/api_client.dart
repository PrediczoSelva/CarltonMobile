import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:carlton_leisure_app/core/constants/app_constants.dart';

/// Thin wrapper around [Dio] shared by every feature's repository.
///
/// Handles: base config, cookie-based session management,
/// and centralised error normalisation.
class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _cookieInterceptor(),
      if (_kEnableLogging)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
    ]);
  }

  late final Dio _dio;
  static const bool _kEnableLogging = true; // flip off for release builds

  final _cookieJar = <String, String>{};

  Dio get dio => _dio;

  Interceptor _cookieInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_cookieJar.isNotEmpty) {
          final cookieHeader = _cookieJar.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
          options.headers['Cookie'] = cookieHeader;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final cookieHeaders = response.headers['set-cookie'];
        if (cookieHeaders != null) {
          for (final cookie in cookieHeaders) {
            final parts = cookie.split(';').first.trim();
            final eqIndex = parts.indexOf('=');
            if (eqIndex > 0 && eqIndex < parts.length - 1) {
              final key = parts.substring(0, eqIndex).trim();
              final value = parts.substring(eqIndex + 1).trim();
              _cookieJar[key] = value;
            }
          }
        }
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    );
  }

  void clearCookies() {
    _cookieJar.clear();
  }

  Map<String, String> get cookies => Map.unmodifiable(_cookieJar);

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