import 'package:flutter/material.dart';

/// A weather condition with its display metadata.
class WeatherCondition {
  const WeatherCondition({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Predicted weather for a single point in time (an airport, at a moment).
class FlightWeather {
  const FlightWeather({
    required this.temperature,
    required this.condition,
    required this.chanceOfRain,
  });

  final int temperature;
  final WeatherCondition condition;
  final int chanceOfRain;
}

/// Predicted weather for the departure and arrival endpoints of a flight.
class FlightWeatherDay {
  const FlightWeatherDay({
    required this.date,
    required this.departure,
    required this.arrival,
  });

  final DateTime date;
  final FlightWeather departure;
  final FlightWeather arrival;
}

/// Hourly reading within a forecast day.
class WeatherHourForecast {
  const WeatherHourForecast({
    required this.label,
    required this.temperature,
    required this.condition,
    required this.chanceOfRain,
  });

  final String label;
  final int temperature;
  final WeatherCondition condition;
  final int chanceOfRain;
}

/// Full forecast for a named place on a given date.
class WeatherForecast {
  const WeatherForecast({
    required this.place,
    required this.date,
    required this.updatedAt,
    required this.temperatureHigh,
    required this.temperatureLow,
    required this.feelsLike,
    required this.condition,
    required this.chanceOfRain,
    required this.windSpeedKph,
    required this.humidity,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
  });

  final String place;
  final DateTime date;
  final String updatedAt;
  final int temperatureHigh;
  final int temperatureLow;
  final int feelsLike;
  final WeatherCondition condition;
  final int chanceOfRain;
  final int windSpeedKph;
  final int humidity;
  final String sunrise;
  final String sunset;
  final List<WeatherHourForecast> hourly;

  bool get isPlaceholder => place.isEmpty;
}

/// Maps a WMO weather code to display metadata. Codes follow the WMO 4677
/// standard returned by Open-Meteo's `weather_code` field.
WeatherCondition conditionForWmoCode(int code) => switch (code) {
      0 => const WeatherCondition(
          label: 'Clear', icon: Icons.wb_sunny, color: Color(0xFFF5A623)),
      1 => const WeatherCondition(
          label: 'Mainly clear',
          icon: Icons.wb_sunny_outlined,
          color: Color(0xFFF5A623)),
      2 => const WeatherCondition(
          label: 'Partly cloudy',
          icon: Icons.cloud_queue,
          color: Color(0xFF7F9BB5)),
      3 => const WeatherCondition(
          label: 'Overcast', icon: Icons.cloud, color: Color(0xFF6B7F92)),
      45 || 48 => const WeatherCondition(
          label: 'Fog', icon: Icons.foggy, color: Color(0xFF9AA5B1)),
      51 || 53 || 55 => const WeatherCondition(
          label: 'Drizzle', icon: Icons.grain, color: Color(0xFF3E7BC0)),
      56 || 57 => const WeatherCondition(
          label: 'Freezing drizzle',
          icon: Icons.grain,
          color: Color(0xFF3E7BC0)),
      61 => const WeatherCondition(
          label: 'Light rain',
          icon: Icons.water_drop_outlined,
          color: Color(0xFF3E7BC0)),
      63 => const WeatherCondition(
          label: 'Rain', icon: Icons.water_drop, color: Color(0xFF2A5FA8)),
      65 => const WeatherCondition(
          label: 'Heavy rain',
          icon: Icons.water_drop,
          color: Color(0xFF1D4380)),
      66 || 67 => const WeatherCondition(
          label: 'Freezing rain',
          icon: Icons.ac_unit,
          color: Color(0xFF4C8B8B)),
      71 || 73 || 75 || 77 => const WeatherCondition(
          label: 'Snow', icon: Icons.ac_unit, color: Color(0xFF7FA8C9)),
      80 => const WeatherCondition(
          label: 'Light showers', icon: Icons.grain, color: Color(0xFF3E7BC0)),
      81 => const WeatherCondition(
          label: 'Showers', icon: Icons.grain, color: Color(0xFF3E7BC0)),
      82 => const WeatherCondition(
          label: 'Heavy showers',
          icon: Icons.thunderstorm,
          color: Color(0xFF5B4B8A)),
      85 || 86 => const WeatherCondition(
          label: 'Snow showers', icon: Icons.ac_unit, color: Color(0xFF7FA8C9)),
      95 || 96 || 99 => const WeatherCondition(
          label: 'Thunderstorm',
          icon: Icons.thunderstorm,
          color: Color(0xFF5B4B8A)),
      _ => const WeatherCondition(
          label: 'Cloudy', icon: Icons.cloud, color: Color(0xFF6B7F92)),
    };
