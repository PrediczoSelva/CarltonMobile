import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/atlas_verify_response.dart';
import '../models/amadeus_verify_response.dart';
import '../models/travelport_verify_response.dart';
import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import 'booking_remote_datasource.dart';

class BookingRemoteDatasourceImpl implements BookingRemoteDatasource {
  BookingRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/bookings';
  static const String _travelportBasePath = '/travelport';

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
      return list
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
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

  @override
  Future<AtlasVerifyResponse> atlasVerify({
    required String routingIdentifier,
    required int adultCount,
    required int childCount,
    required int infantCount,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/atlas/verify',
        data: {
          'routingIdentifier': routingIdentifier,
          'adultCount': adultCount,
          'childCount': childCount,
          'infantCount': infantCount,
        },
      );
      return AtlasVerifyResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BookingModel> atlasBook({
    required String sessionId,
    required String routingIdentifier,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
    required String bookingClass,
    required double quotedTotal,
    String? flightSnapshotJson,
    String? stripePaymentIntentId,
    bool isGuest = false,
  }) async {
    final path =
        isGuest ? '$_basePath/atlas/guest/book' : '$_basePath/atlas/book';
    try {
      final response = await _apiClient.post<dynamic>(
        path,
        data: {
          'sessionId': sessionId,
          'routingIdentifier': routingIdentifier,
          'passengers': passengers,
          'contact': contact,
          'bookingClass': bookingClass,
          'quotedTotal': quotedTotal,
          if (flightSnapshotJson != null)
            'flightSnapshotJson': flightSnapshotJson,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final booking = data['booking'] as Map<String, dynamic>?;
      if (booking == null) {
        throw Exception('Invalid booking response from Atlas.');
      }
      return BookingModel.fromJson(booking);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AmadeusVerifyResponse> amadeusVerify({
    required String amadeusOfferToken,
    required int adultCount,
    required int childCount,
    required int infantCount,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/amadeus/verify',
        data: {
          'amadeusOfferToken': amadeusOfferToken,
          'adultCount': adultCount,
          'childCount': childCount,
          'infantCount': infantCount,
        },
      );
      return AmadeusVerifyResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BookingModel> amadeusBook({
    required String amadeusOfferToken,
    required String verifyId,
    required String stripePaymentIntentId,
    required double baseFareTotal,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
    required String bookingClass,
    required double quotedTotal,
    String? flightSnapshotJson,
    bool isGuest = false,
  }) async {
    final path =
        isGuest ? '$_basePath/amadeus/guest/book' : '$_basePath/amadeus/book';
    try {
      final response = await _apiClient.post<dynamic>(
        path,
        data: {
          'amadeusOfferToken': amadeusOfferToken,
          'verifyId': verifyId,
          'baseFareTotal': baseFareTotal,
          'passengers': passengers,
          'contact': contact,
          'bookingClass': bookingClass,
          'quotedTotal': quotedTotal,
          if (flightSnapshotJson != null)
            'flightSnapshotJson': flightSnapshotJson,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final booking = data['booking'] as Map<String, dynamic>?;
      if (booking == null) {
        throw Exception('Invalid booking response from Amadeus.');
      }
      return BookingModel.fromJson(booking);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TravelportVerifyResponse> travelportVerify({
    required String fareKey,
    required int adults,
    required int children,
    required int infants,
  }) async {
    try {
      debugPrint('[Travelport] verify fareKey=$fareKey adults=$adults children=$children infants=$infants');
      final response = await _apiClient.post<dynamic>(
        '$_travelportBasePath/verify',
        data: {
          'fareKey': fareKey,
          'adults': adults,
          'children': children,
          'infants': infants,
        },
      );
      debugPrint('[Travelport] verify response: ${response.data}');
      return TravelportVerifyResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[Travelport] verify error: ${e.response?.statusCode} ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<BookingModel> travelportBook({
    required String fareKey,
    required List<String> segmentKeys,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
    required String bookingClass,
    required double quotedTotal,
    double providerBaseFare = 0,
    String? flightSnapshotJson,
    String? stripePaymentIntentId,
    bool isGuest = false,
  }) async {
    final path = isGuest
        ? '$_travelportBasePath/guest/book'
        : '$_travelportBasePath/book';
    try {
      debugPrint('[Travelport] book path=$path fareKey=$fareKey passengers=${passengers.length} quotedTotal=$quotedTotal');
      final response = await _apiClient.post<dynamic>(
        path,
        data: {
          'fareKey': fareKey,
          'segmentKeys': segmentKeys,
          'passengers': passengers,
          'contact': contact,
          'bookingClass': bookingClass,
          'quotedTotal': quotedTotal,
          'providerBaseFare': providerBaseFare,
          if (flightSnapshotJson != null)
            'flightSnapshotJson': flightSnapshotJson,
        },
      );
      debugPrint('[Travelport] book response: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      final booking = data['booking'] as Map<String, dynamic>?;
      if (booking == null) {
        throw Exception('Invalid booking response from Travelport.');
      }
      return BookingModel.fromJson(booking);
    } on DioException catch (e) {
      debugPrint('[Travelport] book error: ${e.response?.statusCode} ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<BookingModel> finalizeBookingPayment({
    required int bookingId,
    required String stripePaymentIntentId,
    String? paymentMetadataJson,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/$bookingId/finalize-payment',
        data: {
          'stripePaymentIntentId': stripePaymentIntentId,
          if (paymentMetadataJson != null)
            'paymentMetadataJson': paymentMetadataJson,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('booking')) {
          return BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
        }
        return BookingModel.fromJson(data);
      }
      throw Exception('Invalid finalize payment response.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    debugPrint('[BookingAPI] error type=${e.type} status=${e.response?.statusCode} data=${e.response?.data}');
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
        if (data is Map) {
          final message = data['message'] as String?;
          if (message != null && message.isNotEmpty) return Exception(message);
        }
        final raw = data?.toString().trim();
        if (raw != null && raw.isNotEmpty) return Exception(raw);
        return Exception('Something went wrong. Please try again.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('An unexpected error occurred.');
    }
  }
}
