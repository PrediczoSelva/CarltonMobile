import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import 'hotel_repository.dart';

class HotelRepositoryImpl implements HotelRepository {
  HotelRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<Hotel>> searchHotels(
    HotelSearchCriteria criteria, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/hotels/search',
        query: {
          'destination': criteria.destination,
          'checkIn': _dateFormat.format(criteria.checkIn),
          'checkOut': _dateFormat.format(criteria.checkOut),
          'adults': criteria.adults,
          'children': criteria.children,
          'rooms': criteria.rooms,
          'currency': 'GBP',
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data;
      final rawHotels = data is List
          ? data
          : data is Map
              ? data['hotels'] ?? data['Hotels'] ?? const []
              : const [];
      if (rawHotels is! List) return const [];
      return rawHotels
          .whereType<Map>()
          .map((item) => Hotel.fromJson(Map<String, dynamic>.from(item)))
          .where((hotel) => hotel.price > 0)
          .toList(growable: false);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final responseData = error.response?.data;
      final message =
          responseData is Map ? responseData['message']?.toString() : null;
      if (status == 400) {
        throw Exception(message ?? 'Please check your hotel search details.');
      }
      if (status == 503) {
        throw Exception(
            'Hotel search is temporarily unavailable. Please try again.');
      }
      throw Exception(message ?? 'Unable to load hotels. Please try again.');
    }
  }
}
