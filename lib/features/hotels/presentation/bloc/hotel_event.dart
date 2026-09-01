import '../../domain/entities/hotel_search_criteria.dart';

sealed class HotelSearchEvent {}

class HotelSearchRequested extends HotelSearchEvent {
  HotelSearchRequested(this.criteria);

  final HotelSearchCriteria criteria;
}

class HotelSearchReset extends HotelSearchEvent {}
