import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Dedicated Dio for third-party APIs (currently Open-Meteo).
///
/// [ApiClient] is bound to the Carlton Leisure backend base URL, so it cannot
/// be reused here. This instance has no base URL and no cookie/session logic.
class WeatherApiClient {
  WeatherApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
