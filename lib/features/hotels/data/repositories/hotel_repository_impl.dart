import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import '../../domain/repositories/hotel_repository.dart';
import '../datasources/hotel_remote_datasource.dart';

class HotelRepositoryImpl implements HotelRepository {
  HotelRepositoryImpl(this._remoteDatasource);

  final HotelRemoteDatasource _remoteDatasource;

  @override
  Future<List<Hotel>> searchHotels(HotelSearchCriteria criteria) {
    return _remoteDatasource.searchHotels(criteria);
  }
}
