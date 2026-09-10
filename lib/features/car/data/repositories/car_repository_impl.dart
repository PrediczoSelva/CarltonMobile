import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';
import 'car_repository.dart';

class CarRepositoryImpl implements CarRepository {
  CarRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<CarVehicle>> searchCars(CarSearchCriteria criteria) async {
    try {
      final response =
          await _apiClient.get<dynamic>('/car-hire/search', query: {
        'pickupLocation': criteria.pickupLocation,
        'dropoffLocation': criteria.dropoffLocation,
        'sameDropoff': criteria.sameDropoff,
        'pickupDate': _dateFormat.format(criteria.pickupDate),
        'returnDate': _dateFormat.format(criteria.returnDate),
        'pickupTime': criteria.pickupTime,
        'returnTime': criteria.returnTime,
        'driverAge': criteria.driverAge,
        if (criteria.promoCode?.trim().isNotEmpty == true)
          'promoCode': criteria.promoCode,
        'sort': 'recommended',
      });
      if (response.data is! List) return const [];
      return (response.data as List).whereType<Map>().map((item) {
        return CarVehicle.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load cars. Please try again.');
    }
  }
}
