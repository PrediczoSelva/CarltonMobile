import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarConfirmationScreen extends StatefulWidget {
  const CarConfirmationScreen({
    super.key,
    this.car,
    this.criteria,
    this.total,
    this.extras = const [],
    this.guest = const {},
    this.last4,
  });

  final CarVehicle? car;
  final CarSearchCriteria? criteria;
  final double? total;
  final List<String> extras;
  final Map<String, String> guest;
  final String? last4;

  @override
  State<CarConfirmationScreen> createState() => _CarConfirmationScreenState();
}

class _CarConfirmationScreenState extends State<CarConfirmationScreen> {
  late final String _reference;

  @override
  void initState() {
    super.initState();
    _reference =
        'CAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    _saveBooking();
  }

  void _saveBooking() {
    final car = widget.car;
    final criteria = widget.criteria;
    if (car == null || criteria == null) return;

    getIt<BookingSession>().carBooking = CarBookingRecord(
      reference: _reference,
      car: car,
      criteria: criteria,
      totalPrice: widget.total ?? car.dailyPrice * criteria.rentalDays,
      extras: List.unmodifiable(widget.extras),
      guest: Map.unmodifiable(widget.guest),
      paymentLast4: widget.last4,
      bookingDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final criteria = widget.criteria;
    final days = criteria?.rentalDays ?? 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.success,
              child: Icon(Icons.check, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 18),
          Center(child: Text('Your car is reserved!', style: AppTextStyles.h2)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'A confirmation has been prepared for your rental.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),
          Card(
            color: AppColors.info.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your booking details will be sent to ${widget.guest['email'] ?? 'your email address'}.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section('Booking details', [
            _row('Reference', _reference),
            if (car != null) _row('Vehicle', car.name),
            if (car != null) _row('Rental company', car.companyName),
            _row('Duration', '$days day${days == 1 ? '' : 's'}'),
            if (criteria != null) _row('Pick-up location', criteria.pickupLocation),
            if (widget.extras.isNotEmpty)
              _row('Extras', widget.extras.join(', ')),
          ]),
          const SizedBox(height: 16),
          _section('Payment', [
            _row('Payment method',
                widget.last4 == null ? 'Card' : 'Card ending in ${widget.last4}'),
            _row('Total paid', '£${(widget.total ?? 0).toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Back to home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
