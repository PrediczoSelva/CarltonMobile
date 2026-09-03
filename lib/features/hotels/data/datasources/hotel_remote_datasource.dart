import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';

abstract class HotelRemoteDatasource {
  Future<List<Hotel>> searchHotels(HotelSearchCriteria criteria);
  Future<List<Hotel>> listHotels({String? destination, int maxResults = 10});
}
