import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/payment_intent.dart';
import 'payment_remote_datasource.dart';

class PaymentRemoteDatasourceImpl implements PaymentRemoteDatasource {
  PaymentRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PaymentIntent> createFlightPaymentIntent({
    int? flightId,
    required double amount,
    String? summary,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        if (flightId != null && flightId > 0) 'flightId': flightId,
        if (summary != null && summary.isNotEmpty) 'summary': summary,
      };
      final response = await _apiClient.post<dynamic>(
        AppConstants.paymentCreateFlightIntent,
        data: data,
      );
      return PaymentIntent.fromJson(response.data as Map<String, dynamic>);
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
        if (statusCode == 400) {
          final message = data is Map
              ? (data['error'] as String?) ?? 'Invalid payment details.'
              : 'Invalid payment details.';
          return Exception(message);
        }
        final message = data is Map
            ? (data['error'] as String?) ?? 'Payment failed. Please try again.'
            : 'Payment failed. Please try again.';
        return Exception(message);
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
}
