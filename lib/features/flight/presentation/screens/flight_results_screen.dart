import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class FlightResultsScreen extends StatelessWidget {
  const FlightResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flights = [
      _Flight(
        airline: 'SriLankan Airlines',
        departure: '08:30',
        arrival: '13:45',
        duration: '10h 15m',
        stops: 'Non-stop',
        price: 85000,
      ),
      _Flight(
        airline: 'Emirates',
        departure: '14:20',
        arrival: '20:10',
        duration: '9h 50m',
        stops: '1 stop (DXB)',
        price: 92000,
      ),
      _Flight(
        airline: 'Qatar Airways',
        departure: '22:00',
        arrival: '04:30',
        duration: '10h 30m',
        stops: 'Non-stop',
        price: 88000,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Available flights')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: flights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final flight = flights[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(flight.airline, style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(flight.departure, style: AppTextStyles.h2),
                      const Spacer(),
                      Text(flight.duration, style: AppTextStyles.bodySmall),
                      const Spacer(),
                      Text(flight.arrival, style: AppTextStyles.h2),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(flight.stops, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('LKR ${flight.price.toStringAsFixed(0)}', style: AppTextStyles.price),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Book'),
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
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.stops,
    required this.price,
  });

  final String airline;
  final String departure;
  final String arrival;
  final String duration;
  final String stops;
  final double price;
}
