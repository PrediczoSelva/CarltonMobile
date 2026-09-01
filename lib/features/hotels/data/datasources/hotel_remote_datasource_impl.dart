import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import 'hotel_remote_datasource.dart';

class HotelRemoteDatasourceImpl implements HotelRemoteDatasource {
  HotelRemoteDatasourceImpl(this._apiClient);

  final ApiClient _apiClient;
  static const String _basePath = '/hotels';

  @override
  Future<List<Hotel>> searchHotels(HotelSearchCriteria criteria) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '$_basePath/search',
        query: {
          'Destination': criteria.destination,
          'CheckIn': DateFormat('yyyy-MM-dd').format(criteria.checkIn),
          'CheckOut': DateFormat('yyyy-MM-dd').format(criteria.checkOut),
          'Adults': criteria.adults,
          'Children': criteria.children,
          'Rooms': criteria.rooms,
          'Currency': criteria.currency,
          'Limit': criteria.limit,
          'Offset': criteria.offset,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final hotelsList = data['hotels'] as List<dynamic>? ?? [];
        return hotelsList
            .map((json) => Hotel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid search parameters. Please check your input.');
      }
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Failed to search hotels. Try again.');
    } catch (e) {
      throw Exception('Failed to search hotels. Try again.');
    }
  }
}
