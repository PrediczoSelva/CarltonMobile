import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';
import '../../domain/repositories/flight_repository.dart';
import '../datasources/flight_remote_datasource.dart';

class FlightRepositoryImpl implements FlightRepository {
  FlightRepositoryImpl(this._remoteDatasource);

  final FlightRemoteDatasource _remoteDatasource;

  @override
  Future<List<Flight>> searchFlights(FlightSearchCriteria criteria) {
    return _remoteDatasource.searchFlights(criteria);
  }

  @override
  Future<List<Flight>> getAllFlights() {
    return _remoteDatasource.getAllFlights();
  }

  @override
  Future<Flight?> getFlightById(int id) {
    return _remoteDatasource.getFlightById(id);
  }
}
