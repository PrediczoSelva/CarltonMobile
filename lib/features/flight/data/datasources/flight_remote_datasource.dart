import '../../domain/entities/flight_search_criteria.dart';
import '../models/flight_model.dart';

abstract class FlightRemoteDatasource {
  Future<List<FlightModel>> searchFlights(FlightSearchCriteria criteria);
  Future<FlightModel?> getFlightById(int id);
}
