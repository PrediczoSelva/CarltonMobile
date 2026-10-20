import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/weather_forecast.dart';

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
