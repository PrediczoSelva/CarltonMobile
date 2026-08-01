import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../domain/entities/flight.dart';

class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({super.key});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  late final BookingSession _session;

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
  }

  void _selectFlight(Flight flight) {
    _session.selectedOutboundFlight = flight;
    _session.currency = flight.currency;
    context.push('/booking/passenger-details');
  }

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, MMM d').format(dt);

  @override
  Widget build(BuildContext context) {
    final flights = _session.outboundFlights;
    final criteria = _session.searchCriteria;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available flights'),
        actions: [
          if (flights.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Center(
                child: Text(
                  '${flights.length} flights',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: flights.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flight,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No flights found',
                      style: AppTextStyles.h4,
                    ),
                    if (criteria != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${criteria.originCode} → ${criteria.destinationCode}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.go('/flights/search'),
                      icon: const Icon(Icons.search),
                      label: const Text('Modify search'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: flights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final flight = flights[index];
                return _FlightCard(
                  flight: flight,
                  formatTime: _formatTime,
                  formatDate: _formatDate,
                  onSelect: () => _selectFlight(flight),
                );
              },
            ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.flight,
    required this.formatTime,
    required this.formatDate,
    required this.onSelect,
  });

  final Flight flight;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) formatDate;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flight.flightCode,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
            Text(
              '${formatDate(flight.departureTime)} • ${flight.aircraft}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTime(flight.departureTime),
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 2),
                    Text(flight.origin, style: AppTextStyles.bodySmall),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          flight.duration,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 1,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          flight.stopsText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTime(flight.arrivalTime),
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 2),
                    Text(flight.destination,
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${flight.currency} ${flight.price.toStringAsFixed(0)}',
                  style: AppTextStyles.price,
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
