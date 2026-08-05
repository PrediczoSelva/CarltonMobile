import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import 'booking_remote_datasource.dart';

class BookingRemoteDatasourceImpl implements BookingRemoteDatasource {
  BookingRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/bookings';

  @override
  Future<BookingModel> createBooking(BookingRequest request) async {
    final endpoints = ['$_basePath', '$_basePath/guest'];
    for (final endpoint in endpoints) {
      try {
        final response = await _apiClient.post<dynamic>(
          endpoint,
          data: request.toJson(),
        );
        return BookingModel.fromJson(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && endpoint != endpoints.last) {
          continue;
        }
        throw _handleDioError(e);
      }
    }
    throw Exception('Unable to create booking. Please try again.');
  }

  @override
  Future<List<BookingModel>> getUserBookings() async {
    try {
      final response = await _apiClient.get<dynamic>(_basePath);
      final data = response.data;
      if (data == null) return [];
      final List<dynamic> list = data is List
          ? data
          : (data as Map<String, dynamic>)['bookings'] as List<dynamic>? ?? [];
      return list.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BookingModel?> getBookingById(int id) async {
    try {
      final response = await _apiClient.get<dynamic>('$_basePath/$id');
      if (response.data == null) return null;
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> cancelBooking(int id) async {
    await _apiClient.delete<void>('$_basePath/$id');
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
        if (statusCode == 401) return Exception('Please log in to continue.');
        if (statusCode == 400) {
          final message = data is Map
              ? (data['message'] as String?) ??
                  (data['errors'] is List
                      ? (data['errors'] as List).first.toString()
                      : 'Invalid request.')
              : 'Invalid request.';
          return Exception(message);
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
