import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/cruise.dart';
import '../../domain/entities/cruise_search_criteria.dart';
import 'cruise_repository.dart';

class CruiseRepositoryImpl implements CruiseRepository {
  CruiseRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Cruise>> searchCruises(CruiseSearchCriteria criteria) async {
    try {
      final query = <String, dynamic>{};
      if (criteria.destination.isNotEmpty) {
        query['destination'] = criteria.destination;
      }
      if (criteria.departurePort.isNotEmpty) {
        query['departurePort'] = criteria.departurePort;
      }
      if (criteria.departureMonth.isNotEmpty) {
        query['departureMonth'] = criteria.departureMonth;
      }
      if (criteria.duration != 'all') {
        query['duration'] = criteria.duration;
      }

      final response = await _apiClient.get<dynamic>('/cruises', query: query);
      if (response.data is! List) return const [];
      return (response.data as List)
          .whereType<Map>()
          .map((item) => Cruise.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load cruises. Please try again.');
    }
  }
}
