import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';

abstract class FlightRemoteDatasource {
  Future<List<Flight>> searchFlights(FlightSearchCriteria criteria);
  Future<List<Flight>> getAllFlights();
  Future<Flight?> getFlightById(int id);
}
