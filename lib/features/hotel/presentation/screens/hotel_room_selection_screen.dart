import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import '../../data/repositories/hotel_repository.dart';

class HotelRoomSelectionScreen extends StatefulWidget {
  const HotelRoomSelectionScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
    required this.criteria,
  });

  final String hotelId;
  final String hotelName;
  final HotelSearchCriteria criteria;

  @override
  State<HotelRoomSelectionScreen> createState() =>
      _HotelRoomSelectionScreenState();
}

class _HotelRoomSelectionScreenState extends State<HotelRoomSelectionScreen> {
  late final HotelRepository _repository;
  late final BookingSession _bookingSession;
  List<HotelOffer> _offers = [];
  HotelOffer? _selectedOffer;
  int _roomQuantity = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HotelRepository>();
    _bookingSession = getIt<BookingSession>();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offers = await _repository.getHotelOffers(
        widget.hotelId,
        widget.criteria,
      );
      if (!mounted) return;
      setState(() {
        _offers = offers;
        if (_offers.isNotEmpty) {
          _selectedOffer = _offers.first;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  double get _subtotal {
    if (_selectedOffer == null) return 0.0;
    return (_selectedOffer!.price + _selectedOffer!.taxes) * _roomQuantity;
  }

  double get _taxes {
    if (_selectedOffer == null) return 0.0;
    return _selectedOffer!.taxes * _roomQuantity;
  }

  double get _total => _subtotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotelName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _offers.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Text('Select your room', style: AppTextStyles.h3),
                        const SizedBox(height: 16),
                        _buildRoomCarousel(),
                        const SizedBox(height: 24),
                        _buildQuantitySelector(),
                        const SizedBox(height: 24),
                        _buildBookingSummary(),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Continue to guest details',
                          onPressed: _selectedOffer == null
                              ? null
                              : () => _continueToGuestDetails(context),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error ?? 'Something went wrong.',
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hotel_outlined,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No rooms available', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            const Text('Please try different dates or filters.'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCarousel() {
    return SizedBox(
      height: 420,
      child: PageView.builder(
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final isSelected = _selectedOffer?.offerId == offer.offerId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _RoomCard(
              offer: offer,
              isSelected: isSelected,
              onSelect: () {
                setState(() {
                  _selectedOffer = offer;
                  _roomQuantity = 1;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantitySelector() {
    if (_selectedOffer == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of rooms', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _roomQuantity > 1
                      ? () => setState(() => _roomQuantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: _roomQuantity > 1 ? AppColors.primary : AppColors.disabled,
                ),
                Text(
                  '$_roomQuantity',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: _roomQuantity < 8
                      ? () => setState(() => _roomQuantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: _roomQuantity < 8
                      ? AppColors.primary
                      : AppColors.disabled,
                ),
                const Spacer(),
                Text(
                  'Max 8 rooms',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedOffer == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('d MMM');
    final checkIn = widget.criteria.checkIn;
    final checkOut = widget.criteria.checkOut;
    final nights = checkOut.difference(checkIn).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking summary', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Hotel',
              value: widget.hotelName,
            ),
            _SummaryRow(
              label: 'Room',
              value: _selectedOffer!.roomName,
            ),
            _SummaryRow(
              label: 'Check-in',
              value: dateFormat.format(checkIn),
            ),
            _SummaryRow(
              label: 'Check-out',
              value: dateFormat.format(checkOut),
            ),
            _SummaryRow(
              label: 'Nights',
              value: '$nights night${nights > 1 ? 's' : ''}',
            ),
            _SummaryRow(
              label: 'Rooms',
              value: '$_roomQuantity',
            ),
            _SummaryRow(
              label: 'Adults',
              value: '${widget.criteria.adults}',
            ),
            if (_selectedOffer!.mealPlan != null &&
                _selectedOffer!.mealPlan!.isNotEmpty)
              _SummaryRow(
                label: 'Meal plan',
                value: _selectedOffer!.mealPlan!,
              ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Room price',
              value: '£${_selectedOffer!.price.toStringAsFixed(0)}',
            ),
            _SummaryRow(
              label: 'Taxes & fees',
              value: '£${_taxes.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total', style: AppTextStyles.h4),
                const Spacer(),
                Text(
                  '£${_total.toStringAsFixed(0)}',
                  style: AppTextStyles.price.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _continueToGuestDetails(BuildContext context) {
    if (_selectedOffer == null) return;

    _bookingSession.totalPrice = _total;
    _bookingSession.currency = _selectedOffer!.currency;

    context.push('/booking/passenger-details');
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.offer,
    required this.isSelected,
    required this.onSelect,
  });

  final HotelOffer offer;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final total = offer.price + offer.taxes;
    final image = offer.images.isNotEmpty ? offer.images.first : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                image,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel,
                      size: 40, color: AppColors.primary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(offer.roomName, style: AppTextStyles.h4),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '£${total.toStringAsFixed(0)} total',
                        style: AppTextStyles.price.copyWith(
                          color: isSelected ? AppColors.primary : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (offer.description != null &&
                    offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(offer.description!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 8                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (offer.mealPlan != null && offer.mealPlan!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(offer.mealPlan!,
                            style: AppTextStyles.bodySmall),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          'Max ${offer.maxOccupancy} guest${offer.maxOccupancy == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall),
                    ),
                    if (offer.bedType != null && offer.bedType!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(offer.bedType!,
                            style: AppTextStyles.bodySmall),
                      ),
                  ],
                ),
                if (offer.amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    offer.amenities.take(4).join(' · '),
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (offer.refundable) ...[
                  const SizedBox(height: 8),
                  const Text('Free cancellation',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? AppColors.primary : AppColors.surface,
                      foregroundColor: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.primary,
                    ),
                    child: Text(isSelected ? 'Selected' : 'Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
