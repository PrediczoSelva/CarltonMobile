import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource_impl.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._datasource);

  final WeatherRemoteDatasource _datasource;

  @override
  Future<FlightWeatherDay?> forecastForFlight({
    required String originCode,
    required String destinationCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
  }) {
    return _datasource.forecastForFlight(
      originCode: originCode,
      destinationCode: destinationCode,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
    );
  }

  @override
  Future<WeatherForecast?> forecastForPlace({
    required String place,
    required DateTime date,
  }) {
    return _datasource.forecastForPlace(place: place, date: date);
  }
}
