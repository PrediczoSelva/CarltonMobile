import '../../domain/entities/weather_forecast.dart';

abstract class WeatherRepository {
  /// Predicts weather at an airport for a flight's departure and arrival
  /// moments. Returns null when either endpoint cannot be resolved.
  Future<FlightWeatherDay?> forecastForFlight({
    required String originCode,
    required String destinationCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
  });

  /// Forecast for a free-text place ("London (LHR)" or "Colombo") on a date.
  /// Returns null when the place cannot be geocoded.
  Future<WeatherForecast?> forecastForPlace({
    required String place,
    required DateTime date,
  });
}
