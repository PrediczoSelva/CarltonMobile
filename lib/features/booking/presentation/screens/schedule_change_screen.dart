import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/domain/entities/schedule_change.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../flight/domain/entities/flight_search_criteria.dart';

class ScheduleChangeScreen extends StatefulWidget {
  const ScheduleChangeScreen({
    super.key,
    required this.booking,
    this.scheduleChange,
  });

  final Booking booking;
  final ScheduleChange? scheduleChange;

  @override
  State<ScheduleChangeScreen> createState() => _ScheduleChangeScreenState();
}

class _ScheduleChangeScreenState extends State<ScheduleChangeScreen> {
  late final BookingRepository _bookingRepository;
  late ScheduleChange _scheduleChange;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookingRepository = getIt<BookingRepository>();
    _loadScheduleChange();
  }

  Future<void> _loadScheduleChange() async {
    setState(() => _loading = true);
    try {
      final change = widget.scheduleChange ??
          await _bookingRepository.getScheduleChangeForBooking(widget.booking.id);
      if (change == null) {
        // --- MOCK DATA: Create a sample schedule change for preview ---
        // Remove this block once the real API returns schedule changes.
        final flight = widget.booking.flight;
        final mockChange = ScheduleChange(
          bookingId: widget.booking.id,
          pnr: widget.booking.pnr,
          reason: 'Flight rescheduled due to bad weather conditions',
          originalDepartureTime: flight.departureTime,
          originalArrivalTime: flight.arrivalTime,
          newDepartureTime: flight.departureTime.add(const Duration(hours: 3)),
          newArrivalTime: flight.arrivalTime.add(const Duration(hours: 3)),
          newFlightCode: flight.flightCode,
          newAirline: flight.airline,
          oldFlightCode: flight.flightCode,
          oldAirline: flight.airline,
          priceChange: 0.0,
          currency: widget.booking.currency,
          message: 'Due to bad weather, your flight has been delayed by 3 hours.',
          createdAt: DateTime.now(),
          accepted: false,
        );
        if (!mounted) return;
        setState(() {
          _scheduleChange = mockChange;
          _loading = false;
        });
        return;
      }
      // --- END MOCK DATA ---
      if (!mounted) return;
      setState(() {
        _scheduleChange = change;
        _loading = false;
      });
    } catch (_) {
      // --- MOCK DATA: Create a sample schedule change for preview ---
      final flight = widget.booking.flight;
      final mockChange = ScheduleChange(
        bookingId: widget.booking.id,
        pnr: widget.booking.pnr,
        reason: 'Flight rescheduled due to bad weather conditions',
        originalDepartureTime: flight.departureTime,
        originalArrivalTime: flight.arrivalTime,
        newDepartureTime:
            flight.departureTime.add(const Duration(hours: 3)),
        newArrivalTime: flight.arrivalTime.add(const Duration(hours: 3)),
        newFlightCode: flight.flightCode,
        newAirline: flight.airline,
        oldFlightCode: flight.flightCode,
        oldAirline: flight.airline,
        priceChange: 0.0,
        currency: widget.booking.currency,
        message: 'Due to bad weather, your flight has been delayed by 3 hours.',
        createdAt: DateTime.now(),
        accepted: false,
      );
      if (mounted) {
        setState(() {
          _scheduleChange = mockChange;
          _error = null;
          _loading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'GBP':
        return '£${amount.abs().toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.abs().toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.abs().toStringAsFixed(2)}';
      default:
        return '$currency ${amount.abs().toStringAsFixed(2)}';
    }
  }

  Future<void> _acceptChange() async {
    setState(() => _loading = true);
    try {
      await _bookingRepository.acceptScheduleChange(widget.booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule change accepted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to accept schedule change. Please try again.';
        _loading = false;
      });
    }
  }

  void _findAlternatives() {
    final session = getIt<BookingSession>();
    session.reset();
    session.searchCriteria = FlightSearchCriteria(
      origin: widget.booking.flight.origin,
      destination: widget.booking.flight.destination,
      departureDate: _scheduleChange.newDepartureTime,
      passengers: widget.booking.passengers.length > 0
          ? widget.booking.passengers.length
          : 1,
      tripType: 'one-way',
    );
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.myTrips));
    context.push(AppRoutes.flightSearch);
  }

  Future<void> _requestRefund() async {
    setState(() => _loading = true);
    try {
      await _bookingRepository.requestRefundForScheduleChange(widget.booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund request submitted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to submit refund request. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Change')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Change')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Unable to load schedule change details.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final change = _scheduleChange;
    if (change == null) return const SizedBox.shrink();

    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final timeFmt = DateFormat('HH:mm');
    final priceDiff = change.priceChange;
    final isAdditionalCost = priceDiff > 0;
    final isRefund = priceDiff < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Change')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    change.reason.isNotEmpty
                        ? change.reason
                        : 'Your flight schedule has been changed by the airline.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (change.message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                change.message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Original Schedule',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _scheduleRow(
            airline: change.oldAirline,
            flightCode: change.oldFlightCode,
            departureTime: change.originalDepartureTime,
            arrivalTime: change.originalArrivalTime,
            isOld: true,
            dateFmt: dateFmt,
            timeFmt: timeFmt,
          ),
          const SizedBox(height: 16),
          Text(
            'New Schedule',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _scheduleRow(
            airline: change.newAirline,
            flightCode: change.newFlightCode,
            departureTime: change.newDepartureTime,
            arrivalTime: change.newArrivalTime,
            isOld: false,
            dateFmt: dateFmt,
            timeFmt: timeFmt,
          ),
          if (priceDiff != 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAdditionalCost
                    ? AppColors.error.withOpacity(0.08)
                    : AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdditionalCost
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRefund
                        ? 'Refund due'
                        : 'Additional amount due',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAdditionalCost
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                  Text(
                    isRefund
                        ? '- ${_formatCurrency(priceDiff.abs(), change.currency)}'
                        : '+ ${_formatCurrency(priceDiff.abs(), change.currency)}',
                    style: AppTextStyles.h4.copyWith(
                      color: isAdditionalCost
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'What would you like to do?',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _acceptChange,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_loading ? 'Processing...' : 'Accept new schedule'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _findAlternatives,
            icon: const Icon(Icons.search),
            label: const Text('Find alternatives'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _requestRefund,
            icon: const Icon(Icons.money_off),
            label: const Text('Request refund'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleRow({
    required String airline,
    required String flightCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required bool isOld,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOld ? AppColors.textSecondary : AppColors.success,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$airline · $flightCode',
            style: AppTextStyles.h4.copyWith(
              color: isOld ? AppColors.textSecondary : AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Departure',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateFmt.format(departureTime),
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    timeFmt.format(departureTime),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Arrival',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateFmt.format(arrivalTime),
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    timeFmt.format(arrivalTime),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
