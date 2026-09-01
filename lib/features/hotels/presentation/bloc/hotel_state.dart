import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';

sealed class HotelSearchState {}

class HotelSearchInitial extends HotelSearchState {}

class HotelSearchLoading extends HotelSearchState {}

class HotelSearchLoaded extends HotelSearchState {
  HotelSearchLoaded({
    required this.criteria,
    required this.hotels,
  });

  final HotelSearchCriteria criteria;
  final List<Hotel> hotels;
}

class HotelSearchError extends HotelSearchState {
  HotelSearchError(this.message);

  final String message;
}
