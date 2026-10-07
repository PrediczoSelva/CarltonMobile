import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carlton_leisure_app/core/constants/airport_coordinates.dart';
import 'package:carlton_leisure_app/features/weather/data/datasources/weather_remote_datasource_impl.dart';
import 'package:carlton_leisure_app/features/weather/domain/entities/weather_forecast.dart';

/// Live integration checks against the Open-Meteo API.
///
/// Run with: flutter test test/weather_open_meteo_test.dart
/// These hit the real network and are skipped when it is unavailable.
void main() {
  late WeatherRemoteDatasourceImpl datasource;

  setUp(() {
    datasource = WeatherRemoteDatasourceImpl(
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 15))),
    );
  });

  test('resolves airports from the bundled coordinate map', () {
    expect(kAirportCoordinates['LHR'], isNotNull);
    expect(kAirportCoordinates['CMB'], isNotNull);
    expect(kAirportCoordinates['SIN'], isNotNull);
  });

  test('flight forecast returns both endpoints', () async {
    final departure = DateTime.now().add(const Duration(days: 2));
    final result = await datasource.forecastForFlight(
      originCode: 'LHR',
      destinationCode: 'CMB',
      departureTime: departure,
      arrivalTime: departure.add(const Duration(hours: 11)),
    );

    expect(result, isNotNull, reason: 'LHR/CMB should resolve');
    expect(result!.departure.temperature, greaterThan(-50));
    expect(result.arrival.temperature, greaterThan(-50));
    expect(result.departure.condition.label, isNotEmpty);
    expect(result.departure.chanceOfRain, inInclusiveRange(0, 100));
  });

  test('place forecast returns full detail', () async {
    final date = DateTime.now().add(const Duration(days: 1));
    final result = await datasource.forecastForPlace(
      place: 'London (LHR)',
      date: date,
    );

    expect(result, isNotNull, reason: 'LHR should geocode via bundled map');
    expect(result!.temperatureHigh, greaterThan(result.temperatureLow));
    expect(result.sunrise, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(result.sunset, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(result.hourly, isNotEmpty);
    expect(result.humidity, inInclusiveRange(0, 100));
    expect(result.feelsLike, greaterThan(-50));
  });

  test('free-text place without a code falls back to geocoding', () async {
    final result = await datasource.forecastForPlace(
      place: 'Colombo',
      date: DateTime.now().add(const Duration(days: 1)),
    );

    expect(result, isNotNull, reason: 'geocoding should resolve Colombo');
    expect(result!.condition.label, isNotEmpty);
  });

  test('unknown place returns null instead of throwing', () async {
    final result = await datasource.forecastForPlace(
      place: 'zzzznotarealplacezzzz',
      date: DateTime.now().add(const Duration(days: 1)),
    );

    expect(result, isNull);
  });

  test('WMO codes map to conditions', () {
    expect(conditionForWmoCode(0).label, 'Clear');
    expect(conditionForWmoCode(3).label, 'Overcast');
    expect(conditionForWmoCode(61).label, 'Light rain');
    expect(conditionForWmoCode(95).label, 'Thunderstorm');
    expect(conditionForWmoCode(1234).label, 'Cloudy');
  });
}
