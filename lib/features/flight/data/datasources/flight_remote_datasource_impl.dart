import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';
import 'flight_remote_datasource.dart';

class FlightRemoteDatasourceImpl implements FlightRemoteDatasource {
  FlightRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/flights';

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['flights', 'data', 'results', 'items', 'value']) {
        final val = data[key];
        if (val is List) return val;
      }
    }
    return [];
  }

  @override
  Future<List<Flight>> searchFlights(FlightSearchCriteria criteria) async {
    try {
      final response = await _apiClient.get<dynamic>(_basePath);
      final flights = _parseFlights(response.data);
      if (kDebugMode) {
        print('[FlightSearch] searchFlights: ${flights.length} flights loaded');
        for (final f in flights) {
          print('[FlightSearch]   $f | origin=${f.origin} dest=${f.destination} price=${f.price} ${f.currency}');
        }
      }
      return flights;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (kDebugMode) {
        print('[FlightSearch] DioException: $code, data: ${e.response?.data}');
      }
      if (code == 404 || code == 400) return [];
      if (code == 401) throw Exception('Please log in to continue.');
      throw Exception('Failed to search flights. Try again.');
    } catch (e) {
      if (kDebugMode) {
        print('[FlightSearch] Error: $e');
      }
      throw Exception('Failed to search flights. Try again.');
    }
  }

  @override
  Future<List<Flight>> getAllFlights() async {
    try {
      final response = await _apiClient.get<dynamic>(_basePath);
      final flights = _parseFlights(response.data);
      if (kDebugMode && flights.isNotEmpty) {
        print('[FlightSearch] getAllFlights: ${flights.length} flights loaded');
        for (final f in flights) {
          print('[FlightSearch]   $f | origin=${f.origin} dest=${f.destination} price=${f.price} ${f.currency}');
        }
      }
      return flights;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[FlightSearch] getAllFlights error: ${e.response?.statusCode}, ${e.response?.data}');
      }
      if (e.response?.statusCode == 404) return [];
      throw Exception('Failed to load flights.');
    } catch (e) {
      if (kDebugMode) {
        print('[FlightSearch] getAllFlights error: $e');
      }
      return [];
    }
  }

  List<Flight> _parseFlights(dynamic data) {
    final list = _extractList(data);
    return list.map((json) => Flight.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Flight?> getFlightById(int id) async {
    try {
      final response = await _apiClient.get<dynamic>('$_basePath/$id');
      if (response.data == null) return null;
      final list = _extractList(response.data);
      if (list.isNotEmpty) return Flight.fromJson(list.first as Map<String, dynamic>);
      if (response.data is Map<String, dynamic>) {
        return Flight.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
