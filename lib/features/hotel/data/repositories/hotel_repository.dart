import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';

abstract class HotelRepository {
  Future<List<Hotel>> searchHotels(
    HotelSearchCriteria criteria, {
    int limit = 20,
    int offset = 0,
  });
}
