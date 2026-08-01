import '../../domain/entities/flight_search_criteria.dart';

sealed class FlightSearchEvent {}

class FlightSearchRequested extends FlightSearchEvent {
  FlightSearchRequested(this.criteria);

  final FlightSearchCriteria criteria;
}

class FlightSearchReset extends FlightSearchEvent {}
