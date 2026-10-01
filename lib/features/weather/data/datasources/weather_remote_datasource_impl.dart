import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/airport_coordinates.dart';
import '../../domain/entities/weather_forecast.dart';

abstract class WeatherRemoteDatasource {
  Future<FlightWeatherDay?> forecastForFlight({
    required String originCode,
    required String destinationCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
  });

  Future<WeatherForecast?> forecastForPlace({
    required String place,
    required DateTime date,
  });
}

/// Talks to the Open-Meteo forecast API. Free, no API key required.
///
/// Docs: https://open-meteo.com/en/docs
///
/// Two calls cover every screen:
///  - `forecastForFlight` batches both airports into ONE request.
///  - `forecastForPlace` geocodes the place name, then fetches that location.
class WeatherRemoteDatasourceImpl implements WeatherRemoteDatasource {
  WeatherRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  static const Duration _requestTimeout = Duration(seconds: 15);

  /// Forecast for a given location rarely changes, so responses are cached
  /// per (location, date) for a few hours to stay well inside the free tier.
  final Map<String, (WeatherForecast?, DateTime)> _forecastCache = {};
  static const Duration _cacheTtl = Duration(hours: 3);

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // ---------------------------------------------------------------- flights

  @override
  Future<FlightWeatherDay?> forecastForFlight({
    required String originCode,
    required String destinationCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
  }) async {
    final origin = kAirportCoordinates[originCode.toUpperCase()];
    final destination = kAirportCoordinates[destinationCode.toUpperCase()];
    if (origin == null || destination == null) {
      if (kDebugMode) {
        debugPrint('[Weather] No coordinates for $originCode/$destinationCode');
      }
      return null;
    }

    final dates = <String>{
      _dateFormat.format(departureTime),
      _dateFormat.format(arrivalTime),
    };

    final response = await _getDaily([
      _Location(origin.$1, origin.$2),
      _Location(destination.$1, destination.$2),
    ], dates.toList());

    if (response.length < 2) return null;

    final departureIndex = _indexOfDate(response[0], departureTime);
    final arrivalIndex = _indexOfDate(response[1], arrivalTime);

    return FlightWeatherDay(
      date: departureTime,
      departure: _weatherAt(response[0], departureIndex),
      arrival: _weatherAt(response[1], arrivalIndex),
    );
  }

  // ------------------------------------------------------------------ place

  @override
  Future<WeatherForecast?> forecastForPlace({
    required String place,
    required DateTime date,
  }) async {
    final trimmed = place.trim();
    if (trimmed.isEmpty) return null;

    final code = _extractIataCode(trimmed);
    final coordinates = code != null ? kAirportCoordinates[code] : null;

    // Prefer the bundled airport lookup; fall back to Open-Meteo geocoding
    // for free-text place names.
    final (double, double)? resolved = coordinates ??
        await _geocode(
            trimmed.replaceAll(RegExp(r'\s*\([A-Z]{3}\)'), '').trim());
    if (resolved == null) return null;

    final cacheKey =
        '${resolved.$1},${resolved.$2}|${_dateFormat.format(date)}';
    final cached = _forecastCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.$2) < _cacheTtl) {
      return cached.$1;
    }

    final response = await _getDaily(
      [_Location(resolved.$1, resolved.$2)],
      [_dateFormat.format(date)],
    );
    if (response.isEmpty) return null;

    final day = response.first;
    final index = _indexOfDate(day, date);
    final daily = _dailyBlock(day, index);

    final forecast = WeatherForecast(
      place: trimmed,
      date: date,
      updatedAt: 'Just now',
      temperatureHigh: _intAt(day, 'temperature_2m_max', index),
      temperatureLow: _intAt(day, 'temperature_2m_min', index),
      feelsLike: _averageHourly(day, index, 'apparent_temperature'),
      condition: conditionForWmoCode(_intAt(day, 'weather_code', index)),
      chanceOfRain: _intAt(day, 'precipitation_probability_max', index),
      windSpeedKph: _intAt(day, 'wind_speed_10m_max', index),
      humidity: _averageHourly(day, index, 'relative_humidity_2m'),
      sunrise: _extractIsoTime(daily['sunrise']),
      sunset: _extractIsoTime(daily['sunset']),
      hourly: _hourlyFrom(day),
    );

    _forecastCache[cacheKey] = (forecast, DateTime.now());
    return forecast;
  }

  // ------------------------------------------------------------------ http

  Future<List<Map<String, dynamic>>> _getDaily(
    List<_Location> locations,
    List<String> dates,
  ) async {
    final latitudes = locations.map((l) => l.latitude).join(',');
    final longitudes = locations.map((l) => l.longitude).join(',');
    final start = dates.first;
    final end = dates.last;

    final url = '${AppConstants.openMeteoBaseUrl}/forecast'
        '?latitude=$latitudes'
        '&longitude=$longitudes'
        // Only these fields exist on the `daily` block. Apparent temperature
        // and humidity are hourly/current-only, so they are derived from
        // `hourly` below.
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,'
        'precipitation_probability_max,wind_speed_10m_max,sunrise,sunset'
        '&hourly=temperature_2m,weather_code,precipitation_probability,'
        'relative_humidity_2m,apparent_temperature'
        // GMT keeps the returned date arrays identical for every location,
        // which is what lets us match a result back to a flight date.
        '&timezone=GMT'
        '&start_date=$start'
        '&end_date=$end';

    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );
      return _normalize(response.data);
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('[Weather] Request failed: ${error.message}');
      }
      return [];
    }
  }

  /// Open-Meteo returns a bare object for one location and an array for
  /// several. Normalise both to a list.
  List<Map<String, dynamic>> _normalize(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) return [data];
    return [];
  }

  Future<(double, double)?> _geocode(String name) async {
    if (name.isEmpty) return null;
    try {
      final response = await _dio.get<dynamic>(
        '${AppConstants.openMeteoGeocodingBaseUrl}/search',
        queryParameters: {'name': name, 'count': 1, 'language': 'en'},
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data is Map &&
          data['results'] is List &&
          data['results'].isNotEmpty) {
        final first = data['results'][0];
        if (first is Map && first['latitude'] != null) {
          return (
            (first['latitude'] as num).toDouble(),
            (first['longitude'] as num).toDouble(),
          );
        }
      }
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('[Weather] Geocoding failed: ${error.message}');
      }
    }
    return null;
  }

  // --------------------------------------------------------------- parsing

  int _indexOfDate(Map<String, dynamic> day, DateTime date) {
    final times = day['daily']?['time'] as List<dynamic>?;
    final target = _dateFormat.format(date);
    if (times == null) return 0;
    final index = times.indexOf(target);
    return index >= 0 ? index : 0;
  }

  FlightWeather _weatherAt(Map<String, dynamic> day, int index) {
    return FlightWeather(
      temperature: _intAt(day, 'temperature_2m_max', index),
      condition: conditionForWmoCode(_intAt(day, 'weather_code', index)),
      chanceOfRain: _intAt(day, 'precipitation_probability_max', index),
    );
  }

  List<WeatherHourForecast> _hourlyFrom(Map<String, dynamic> day) {
    final hourly = day['hourly'];
    if (hourly is! Map<String, dynamic>) return const [];

    final times = hourly['time'] as List<dynamic>?;
    final temps = hourly['temperature_2m'] as List<dynamic>?;
    final codes = hourly['weather_code'] as List<dynamic>?;
    final rain = hourly['precipitation_probability'] as List<dynamic>?;
    if (times == null || temps == null || codes == null) return const [];

    final forecasts = <WeatherHourForecast>[];
    for (var i = 0; i < times.length; i++) {
      // The request pins timezone=GMT, so the returned timestamps are UTC.
      // Parse as UTC and read the UTC hour rather than converting to device
      // local time, which would shift every reading for non-UTC devices.
      final hour = DateTime.tryParse('${times[i]}Z')?.toUtc();
      if (hour == null || hour.hour < 6 || hour.hour > 21) continue;

      forecasts.add(
        WeatherHourForecast(
          label: DateFormat.Hm().format(hour),
          temperature: (temps[i] as num?)?.round() ?? 0,
          condition: conditionForWmoCode((codes[i] as num?)?.round() ?? 0),
          chanceOfRain: (rain?[i] as num?)?.round() ?? 0,
        ),
      );
      // A full day of hours is too much for the strip; cap the list.
      if (forecasts.length == 8) break;
    }
    return forecasts;
  }

  /// Returns the `daily` entry at [index] as a flat map, so sunrise/sunset can
  /// be read with the same indexing as the numeric arrays.
  Map<String, dynamic> _dailyBlock(Map<String, dynamic> day, int index) {
    final daily = day['daily'];
    if (daily is! Map<String, dynamic>) return const {};
    final result = <String, dynamic>{};
    daily.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        result[key] = value[index < value.length ? index : 0];
      }
    });
    return result;
  }

  /// Averages an hourly-only variable (apparent temperature, humidity) across
  /// the requested day. Open-Meteo has no daily equivalent for these.
  int _averageHourly(Map<String, dynamic> day, int index, String field) {
    final hourly = day['hourly'];
    if (hourly is! Map<String, dynamic>) return 0;

    final values = hourly[field] as List<dynamic>?;
    final times = hourly['time'] as List<dynamic>?;
    if (values == null || times == null) return 0;

    final dayKey = _dayKey(index, day, times);
    final totals = <String, double>{};

    for (var i = 0; i < times.length && i < values.length; i++) {
      final value = values[i];
      if (value is! num) continue;
      final key = '${times[i]}'.split('T').first;
      totals[key] = (totals[key] ?? 0) + value;
    }
    if (totals.isEmpty) return 0;

    final matching = totals[dayKey];
    if (matching != null) {
      // Divide by the number of hourly samples that fell on the target day.
      final count =
          times.where((t) => '${t}'.split('T').first == dayKey).length;
      if (count > 0) return (matching / count).round();
    }

    // Out-of-range forecast date: fall back to a whole-response average.
    final sum = totals.values.fold<double>(0, (a, b) => a + b);
    return (sum / totals.length).round();
  }

  /// The `yyyy-MM-dd` prefix shared by every hourly timestamp on day [index].
  String _dayKey(int index, Map<String, dynamic> day, List<dynamic> times) {
    final dailyTimes = day['daily']?['time'] as List<dynamic>?;
    if (dailyTimes != null && index < dailyTimes.length) {
      return '${dailyTimes[index]}';
    }
    return times.isEmpty ? '' : '${times[0]}'.split('T').first;
  }

  int _intAt(
    Map<String, dynamic> day,
    String field,
    int index, {
    int fallback = 0,
  }) {
    final values = day['daily']?[field] as List<dynamic>?;
    if (values == null || index >= values.length) return fallback;
    final value = values[index];
    return value is num ? value.round() : fallback;
  }

  /// Open-Meteo returns sunrise/sunset as full ISO timestamps; the UI only
  /// wants the clock portion.
  String _extractIsoTime(dynamic value) {
    if (value is! String || value.isEmpty) return '--:--';
    final match = RegExp(r'T(\d{2}:\d{2})').firstMatch(value);
    return match?.group(1) ?? value;
  }

  String? _extractIataCode(String input) {
    final match = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(input);
    if (match != null) return match.group(1)!.toUpperCase();
    final bare = RegExp(r'^([A-Za-z]{3})$').firstMatch(input.trim());
    return bare != null ? bare.group(1)!.toUpperCase() : null;
  }
}

class _Location {
  const _Location(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
