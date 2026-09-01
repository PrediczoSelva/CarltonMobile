import '../entities/hotel.dart';
import '../entities/hotel_search_criteria.dart';

abstract class HotelRepository {
  Future<List<Hotel>> searchHotels(HotelSearchCriteria criteria);
}
