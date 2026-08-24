import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';
import 'wallet_remote_datasource.dart';

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  WalletRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<WalletBalance> getWalletSummary() async {
    try {
      final response = await _apiClient.get<dynamic>('/wallet/summary');
      final model = WalletBalanceModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return model.toEntity();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _apiClient.get<dynamic>('/wallet/transactions');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => WalletTransactionModel.fromJson(
                  e as Map<String, dynamic>,
                ).toEntity())
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> createTopUpPaymentIntent({
    required double amount,
    required String currency,
    int? savedCardId,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        if (savedCardId != null) 'savedPaymentMethodId': savedCardId,
      };
      final response = await _apiClient.post<dynamic>(
        '/wallet/topup/payment-intent',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;
      return responseData['clientSecret'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> confirmTopUp({required String paymentIntentId}) async {
    try {
      await _apiClient.post<dynamic>(
        '/wallet/topup/confirm',
        data: {'stripePaymentIntentId': paymentIntentId},
      );
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
        final data = e.response?.data;
        final message = data is Map
            ? (data['error'] as String?) ?? 'Failed to load wallet data.'
            : 'Failed to load wallet data.';
        return Exception(message);
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
}
