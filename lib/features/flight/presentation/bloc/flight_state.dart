import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';

sealed class FlightSearchState {}

class FlightSearchInitial extends FlightSearchState {}

class FlightSearchLoading extends FlightSearchState {}

class FlightSearchLoaded extends FlightSearchState {
  FlightSearchLoaded({
    required this.criteria,
    required this.flights,
  });

  final FlightSearchCriteria criteria;
  final List<Flight> flights;
}

class FlightSearchError extends FlightSearchState {
  FlightSearchError(this.message);

  final String message;
}
