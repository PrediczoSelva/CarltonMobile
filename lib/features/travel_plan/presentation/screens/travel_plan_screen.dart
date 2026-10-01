import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

class TravelPlanScreen extends StatefulWidget {
  const TravelPlanScreen({super.key});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

enum _TripFilter { allTrips, multiCity, returnTrip, oneWay }

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  _TripFilter _filter = _TripFilter.allTrips;

  final List<TravelPlan> _trips = [
    TravelPlan(
      tripName: 'India Tour',
      tripType: TripType.returnTrip,
      cabinClass: 'Business',
      adults: 1,
      children: 0,
      infants: 0,
      fromDate: DateTime(2026, 11, 15),
      toDate: DateTime(2026, 9, 20),
      budgetType: 'Maximum',
      currency: 'USD',
      maxBudget: 0,
      savedAt: DateTime(2026, 9, 16),
      flights: const [
        TravelPlanFlight(
            departureAirport: 'Colombo, Sri Lanka (CMB)',
            arrivalAirport: 'Gandhi, India (DEL)'),
      ],
    ),
  ];

  List<TravelPlan> get _filteredTrips {
    switch (_filter) {
      case _TripFilter.allTrips:
        return _trips;
      case _TripFilter.multiCity:
        return _trips.where((t) => t.tripType == TripType.multiCity).toList();
      case _TripFilter.returnTrip:
        return _trips.where((t) => t.tripType == TripType.returnTrip).toList();
      case _TripFilter.oneWay:
        return _trips.where((t) => t.tripType == TripType.oneWay).toList();
    }
  }

  void _openPlanNewTrip() {
    context.push(AppRoutes.travelPlanCreate);
  }

  void _editTrip(TravelPlan trip) {
    context.push(AppRoutes.travelPlanCreate);
  }

  Future<void> _deleteTrip(TravelPlan trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete travel plan'),
        content: Text('Delete "${trip.tripName}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _trips.remove(trip));
    }
  }

  void _bookNow(TravelPlan trip) {
    context.push(AppRoutes.flightSearch);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trips = _filteredTrips;
    final isFiltered = _filter != _TripFilter.allTrips;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surface,
      appBar: AppBar(
        title: const Text('Travel Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            "Plan now, book whenever you're ready — your travel stays saved.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openPlanNewTrip,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Plan New Trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FilterChips(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 20),
          if (trips.isEmpty)
            _EmptyState(
              isFiltered: isFiltered,
              onPlanNewTrip: _openPlanNewTrip,
            )
          else
            Column(
              children: [
                for (final trip in trips) ...[
                  _TripCard(
                    trip: trip,
                    onEdit: () => _editTrip(trip),
                    onDelete: () => _deleteTrip(trip),
                    onBookNow: () => _bookNow(trip),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

enum TripType { multiCity, returnTrip, oneWay }

class TravelPlanFlight {
  const TravelPlanFlight({
    required this.departureAirport,
    required this.arrivalAirport,
    this.fromDate,
  });

  final String departureAirport;
  final String arrivalAirport;
  final DateTime? fromDate;
}

class TravelPlan {
  const TravelPlan({
    required this.tripName,
    required this.tripType,
    required this.cabinClass,
    this.preferredAirline,
    required this.adults,
    required this.children,
    required this.infants,
    required this.fromDate,
    required this.toDate,
    required this.budgetType,
    required this.currency,
    required this.maxBudget,
    this.savedAt,
    this.notes,
    required this.flights,
    this.autoBookingEnabled = false,
    this.receiveBookingNotification = true,
  });

  final String tripName;
  final TripType tripType;
  final String cabinClass;
  final String? preferredAirline;
  final int adults;
  final int children;
  final int infants;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetType;
  final String currency;
  final double maxBudget;
  final DateTime? savedAt;
  final String? notes;
  final List<TravelPlanFlight> flights;
  final bool autoBookingEnabled;
  final bool receiveBookingNotification;
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});
  final _TripFilter selected;
  final ValueChanged<_TripFilter> onChanged;

  static const _labels = {
    _TripFilter.allTrips: 'All Trips',
    _TripFilter.multiCity: 'Multi-City',
    _TripFilter.returnTrip: 'Return',
    _TripFilter.oneWay: 'One Way',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.background,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: selected == entry.key
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color:
                selected == entry.key ? AppColors.primary : AppColors.border,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered, required this.onPlanNewTrip});
  final bool isFiltered;
  final VoidCallback onPlanNewTrip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching travel plans' : 'No travel plans yet',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Try a different filter or create a new trip.'
                : 'Create your first plan to save routes, dates, and preferences for later booking.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPlanNewTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('Plan New Trip'),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
    required this.onBookNow,
  });

  final TravelPlan trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBookNow;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  String get _tripTypeLabel {
    switch (trip.tripType) {
      case TripType.multiCity:
        return 'MULTI-CITY';
      case TripType.returnTrip:
        return 'RETURN';
      case TripType.oneWay:
        return 'ONE WAY';
    }
  }

  int get _paxCount => trip.adults + trip.children + trip.infants;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legs = trip.flights.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_tripTypeLabel,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 6),
                    Text(trip.tripName,
                        style: AppTextStyles.h4.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.primary)),
                  ],
                ),
              ),
              _IconSquareButton(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 6),
              _IconSquareButton(
                icon: Icons.delete_outline,
                onTap: onDelete,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                for (final leg in legs) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(leg.departureAirport,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 14, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          leg.arrivalAirport,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_fmtDate(trip.fromDate)} – ${_fmtDate(trip.toDate)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaChip(icon: Icons.people_outline, label: '$_paxCount Pax'),
                    _MetaChip(
                        icon: Icons.airline_seat_recline_normal_outlined,
                        label: trip.cabinClass),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Book Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Icon(icon, size: 15, color: color ?? AppColors.textSecondary),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}