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

  String _formatDate(DateTime dt) => DateFormat('EEE, MMM d').format(dt);

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
                        '${criteria.originCode} -> ${criteria.destinationCode}',
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

class _FlightCard extends StatefulWidget {
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
  State<_FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<_FlightCard> {
  bool _isHovered = false;

  String _providerLabel(String source) {
    final normalized = source.trim().toLowerCase();

    if (normalized.contains('travelport')) {
      return 'Travelport';
    }
    if (normalized.contains('amadeus') ||
        normalized.contains('amedias') ||
        normalized.contains('amadea')) {
      return 'Amadeus';
    }
    if (normalized.contains('atlas')) {
      return 'Atlas';
    }

    if (normalized.isEmpty) {
      return 'Catalog';
    }

    return source.trim();
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final provider = _providerLabel(flight.source);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppColors.accent.withOpacity(0.45)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_isHovered ? 0.17 : 0.09),
              blurRadius: _isHovered ? 28 : 16,
              offset: Offset(0, _isHovered ? 12 : 7),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.surface,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onSelect,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          flight.airline,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          flight.flightCode,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Provider: $provider',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.formatDate(flight.departureTime)} - ${flight.aircraft}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.formatTime(flight.departureTime),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.origin,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(
                                flight.duration.isNotEmpty
                                    ? flight.duration
                                    : flight.stopsText,
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent,
                                    ],
                                  ),
                                ),
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
                            widget.formatTime(flight.arrivalTime),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.destination,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${flight.currency} ${flight.price.toStringAsFixed(0)}',
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          onPressed: widget.onSelect,
                          style: ElevatedButton.styleFrom(
                            elevation: _isHovered ? 1 : 0,
                          ),
                          child: const Text('Select'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
