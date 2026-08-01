import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/flight_search_criteria.dart';
import '../models/flight_model.dart';
import 'flight_remote_datasource.dart';

class FlightRemoteDatasourceImpl implements FlightRemoteDatasource {
  FlightRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/flights';

  @override
  Future<List<FlightModel>> searchFlights(FlightSearchCriteria criteria) async {
    try {
      final response = await _apiClient.get<dynamic>(
        _basePath,
        query: {
          'origin': criteria.originCode,
          'destination': criteria.destinationCode,
          'departureDate': criteria.departureDate.toIso8601String(),
          if (criteria.returnDate != null)
            'returnDate': criteria.returnDate!.toIso8601String(),
          'passengers': criteria.passengers,
        },
      );

      final data = response.data;
      if (data == null) return [];

      final List<dynamic> list = data is List
          ? data
          : (data as Map<String, dynamic>)['flights'] as List<dynamic>? ?? [];

      return list.map((json) => FlightModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FlightModel?> getFlightById(int id) async {
    try {
      final response = await _apiClient.get<dynamic>('$_basePath/$id');
      if (response.data == null) return null;
      return FlightModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
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
        if (statusCode == 404) return Exception('No flights found for your search.');
        if (statusCode == 401) return Exception('Please log in to continue.');
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
