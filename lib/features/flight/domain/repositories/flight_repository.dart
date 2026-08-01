import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';

abstract class FlightRepository {
  Future<List<Flight>> searchFlights(FlightSearchCriteria criteria);
  Future<Flight?> getFlightById(int id);
}
