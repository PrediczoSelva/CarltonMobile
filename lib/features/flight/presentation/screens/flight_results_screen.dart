import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FlightResultsScreen extends StatelessWidget {
  const FlightResultsScreen({super.key});

  static const _flights = [
    _Flight(
      airline: 'SriLankan Airlines',
      flightCode: 'UL 101',
      departure: '08:30',
      arrival: '13:45',
      duration: '10h 15m',
      stops: 'Non-stop',
      price: 85000,
      aircraft: 'Airbus A320',
    ),
    _Flight(
      airline: 'Emirates',
      flightCode: 'EK 654',
      departure: '14:20',
      arrival: '20:10',
      duration: '9h 50m',
      stops: '1 stop (DXB)',
      price: 92000,
      aircraft: 'Boeing 777',
    ),
    _Flight(
      airline: 'Qatar Airways',
      flightCode: 'QR 448',
      departure: '22:00',
      arrival: '04:30',
      duration: '10h 30m',
      stops: 'Non-stop',
      price: 88000,
      aircraft: 'Airbus A350',
    ),
    _Flight(
      airline: 'Singapore Airlines',
      flightCode: 'SQ 468',
      departure: '07:15',
      arrival: '15:05',
      duration: '9h 50m',
      stops: '1 stop (SIN)',
      price: 95000,
      aircraft: 'Airbus A380',
    ),
    _Flight(
      airline: 'Maldivian',
      flightCode: 'Q2 102',
      departure: '11:00',
      arrival: '13:30',
      duration: '2h 30m',
      stops: 'Non-stop',
      price: 42000,
      aircraft: 'ATR 72',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available flights')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _flights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final flight = _flights[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(flight.airline, style: AppTextStyles.h4),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(flight.flightCode, style: AppTextStyles.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flight.departure, style: AppTextStyles.h2),
                          const SizedBox(height: 2),
                          Text('CMB', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(flight.duration, style: AppTextStyles.bodySmall),
                              const SizedBox(height: 4),
                              Container(
                                height: 1,
                                color: AppColors.border,
                              ),
                              const SizedBox(height: 4),
                              Text(flight.stops, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(flight.arrival, style: AppTextStyles.h2),
                          const SizedBox(height: 2),
                          Text(flight.aircraft.split(' ').last, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('LKR ${flight.price.toStringAsFixed(0)}', style: AppTextStyles.price),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () => context.push('/booking/passenger-details'),
                          child: const Text('Book'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Flight {
  const _Flight({
    required this.airline,
    required this.flightCode,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.stops,
    required this.price,
    required this.aircraft,
  });

  final String airline;
  final String flightCode;
  final String departure;
  final String arrival;
  final String duration;
  final String stops;
  final double price;
  final String aircraft;
}
