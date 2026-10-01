import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/flight.dart';

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

/// Predicted weather for one endpoint of a flight.
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

/// Predicted weather for a flight on its departure date.
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

/// Conditions used to render dummy data. Replace [buildFlightWeather] with a
/// real weather API call when an API key is available.
const flightWeatherConditions = <WeatherCondition>[
  WeatherCondition(
    label: 'Sunny',
    icon: Icons.wb_sunny,
    color: Color(0xFFF5A623),
  ),
  WeatherCondition(
    label: 'Partly cloudy',
    icon: Icons.cloud_queue,
    color: Color(0xFF7F9BB5),
  ),
  WeatherCondition(
    label: 'Cloudy',
    icon: Icons.cloud,
    color: Color(0xFF6B7F92),
  ),
  WeatherCondition(
    label: 'Light rain',
    icon: Icons.grain,
    color: Color(0xFF3E7BC0),
  ),
  WeatherCondition(
    label: 'Rainy',
    icon: Icons.water_drop,
    color: Color(0xFF2A5FA8),
  ),
  WeatherCondition(
    label: 'Showers',
    icon: Icons.thunderstorm,
    color: Color(0xFF5B4B8A),
  ),
  WeatherCondition(label: 'Windy', icon: Icons.air, color: Color(0xFF4C8B8B)),
  WeatherCondition(
    label: 'Clear',
    icon: Icons.nightlight_round,
    color: Color(0xFF3D4A6B),
  ),
];

/// Dummy forecast derived deterministically from the flight id, so the same
/// flight always renders the same weather. Swap for a real API call later.
FlightWeatherDay buildFlightWeather(Flight flight) {
  final seed = flight.id.abs();

  FlightWeather pick(int offset) {
    return FlightWeather(
      temperature: 14 + ((seed + offset * 7) % 18),
      condition:
          flightWeatherConditions[(seed + offset * 3) %
              flightWeatherConditions.length],
      chanceOfRain: (seed + offset * 11) % 100,
    );
  }

  return FlightWeatherDay(
    date: flight.departureTime,
    departure: pick(1),
    arrival: pick(2),
  );
}

/// Hourly reading within a single forecast day.
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

/// Full day forecast for a named place on a given date.
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
}

/// Dummy forecast for a named [place] on [date], derived deterministically from
/// the place and date so repeated searches return the same result.
/// Swap for a real API call later.
WeatherForecast buildPlaceWeather(String place, DateTime date) {
  final seed =
      place.trim().toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b) +
      date.year * 372 +
      date.month * 31 +
      date.day;

  WeatherCondition conditionAt(int offset) =>
      flightWeatherConditions[(seed + offset * 5) %
          flightWeatherConditions.length];

  final hourly = <WeatherHourForecast>[];
  for (var hour = 8; hour <= 19; hour += 3) {
    hourly.add(
      WeatherHourForecast(
        label: '${hour.toString().padLeft(2, '0')}:00',
        temperature: 12 + ((seed + hour * 3) % 16),
        condition: conditionAt(hour),
        chanceOfRain: (seed + hour * 13) % 100,
      ),
    );
  }

  return WeatherForecast(
    place: place.trim(),
    date: date,
    updatedAt: 'Just now',
    temperatureHigh: 18 + (seed % 12),
    temperatureLow: 8 + (seed % 8),
    feelsLike: 16 + (seed % 12),
    condition: conditionAt(1),
    chanceOfRain: (seed * 7) % 100,
    windSpeedKph: 4 + (seed % 28),
    humidity: 35 + (seed % 55),
    sunrise: '06:1${seed % 9}',
    sunset: '18:2${seed % 8}',
    hourly: hourly,
  );
}

/// Predicted-weather panel shown under a flight card.
class FlightWeatherStrip extends StatelessWidget {
  const FlightWeatherStrip({
    super.key,
    required this.weather,
    required this.formatDate,
    required this.origin,
    required this.destination,
  });

  final FlightWeatherDay weather;
  final String Function(DateTime) formatDate;
  final String origin;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Weather on ${formatDate(weather.date)}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _WeatherPill(
                  label: 'Departure',
                  place: origin,
                  weather: weather.departure,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeatherPill(
                  label: 'Arrival',
                  place: destination,
                  weather: weather.arrival,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherPill extends StatelessWidget {
  const _WeatherPill({
    required this.label,
    required this.place,
    required this.weather,
  });

  final String label;
  final String place;
  final FlightWeather weather;

  @override
  Widget build(BuildContext context) {
    final condition = weather.condition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: condition.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(condition.icon, size: 18, color: condition.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${weather.temperature}°',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        condition.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: condition.color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    Text(
                      '${weather.chanceOfRain}% rain',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Text(
                  '$label · $place',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
