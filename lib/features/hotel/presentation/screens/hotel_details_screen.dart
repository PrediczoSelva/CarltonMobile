import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import '../../data/repositories/hotel_repository.dart';

class HotelDetailsScreen extends StatefulWidget {
  const HotelDetailsScreen({
    super.key,
    required this.hotelId,
    required this.criteria,
  });

  final String hotelId;
  final HotelSearchCriteria criteria;

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  late final HotelRepository _repository;
  Hotel? _hotel;
  List<HotelOffer> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HotelRepository>();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getHotelDetails(widget.hotelId),
        _repository.getHotelOffers(widget.hotelId, widget.criteria),
      ]);
      if (!mounted) return;
      setState(() {
        _hotel = results[0] as Hotel;
        _offers = results[1] as List<HotelOffer>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _hotel == null
                  ? const Center(child: Text('Hotel not found.'))
                  : RefreshIndicator(
                      onRefresh: _loadDetails,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _buildImageCarousel(),
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 16),
                          if (_hotel!.description != null &&
                              _hotel!.description!.isNotEmpty)
                            _buildDescription(),
                          if (_hotel!.description != null &&
                              _hotel!.description!.isNotEmpty)
                            const SizedBox(height: 16),
                          if (_hotel!.policies != null) _buildPolicies(),
                          if (_hotel!.policies != null)
                            const SizedBox(height: 16),
                          _buildAmenitiesSection(),
                          const SizedBox(height: 16),
                          _buildRoomTypes(),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Reserve now',
                            onPressed: () => _reserve(context),
                          ),
                        ],
                      ),
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
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final allImages = <String>[];
    if (_hotel!.thumbnail != null && _hotel!.thumbnail!.isNotEmpty) {
      allImages.add(_hotel!.thumbnail!);
    }
    for (final image in _hotel!.images) {
      if (image.isNotEmpty && !allImages.contains(image)) {
        allImages.add(image);
      }
    }
    for (final room in _hotel!.roomTypes) {
      for (final image in room.images) {
        if (image.isNotEmpty && !allImages.contains(image)) {
          allImages.add(image);
        }
      }
    }

    if (allImages.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.hotel, size: 64, color: AppColors.primary),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final imageUrl = allImages[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel,
                      size: 48, color: AppColors.primary),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final dateFormat = DateFormat('d MMM');
    final checkIn = widget.criteria.checkIn;
    final checkOut = widget.criteria.checkOut;
    final nights = checkOut.difference(checkIn).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_hotel!.name, style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _hotel!.location,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_hotel!.starRating > 0) ...[
              const Icon(Icons.star, size: 18, color: AppColors.accent),
              Text(' ${_hotel!.starRating} stars',
                  style: AppTextStyles.bodyMedium),
            ],
            if (_hotel!.guestRating > 0) ...[
              const SizedBox(width: 12),
              const Icon(Icons.thumb_up_outlined,
                  size: 18, color: AppColors.textSecondary),
              Text(' Guest ${_hotel!.guestRating.toStringAsFixed(1)}',
                  style: AppTextStyles.bodyMedium),
            ],
            const Spacer(),
            Text(
              '£${_hotel!.price.toStringAsFixed(0)} / night',
              style: AppTextStyles.price,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)} · $nights night${nights > 1 ? 's' : ''} · ${widget.criteria.adults} guest${widget.criteria.adults > 1 ? 's' : ''} · ${widget.criteria.rooms} room${widget.criteria.rooms > 1 ? 's' : ''}',
            style: AppTextStyles.bodySmall,
          ),
        ),
        if (_hotel!.refundable) ...[
          const SizedBox(height: 8),
          const Text('Free cancellation',
              style: TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Text(_hotel!.description!, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildPolicies() {
    final policies = _hotel!.policies!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hotel policies', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        if (policies.checkIn != null && policies.checkIn!.isNotEmpty)
          _buildPolicyRow(Icons.login, 'Check-in', policies.checkIn!),
        if (policies.checkOut != null && policies.checkOut!.isNotEmpty)
          _buildPolicyRow(Icons.logout, 'Check-out', policies.checkOut!),
        if (policies.cancellation != null && policies.cancellation!.isNotEmpty)
          _buildPolicyRow(
              Icons.event_busy, 'Cancellation', policies.cancellation!),
        if (policies.children != null && policies.children!.isNotEmpty)
          _buildPolicyRow(Icons.child_care, 'Children', policies.children!),
        if (policies.pets != null && policies.pets!.isNotEmpty)
          _buildPolicyRow(Icons.pets, 'Pets', policies.pets!),
      ],
    );
  }

  Widget _buildPolicyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final allAmenities = <String>[..._hotel!.amenities];
    if (_hotel!.facilities.isNotEmpty) {
      allAmenities.addAll(_hotel!.facilities);
    }

    if (allAmenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities & facilities', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allAmenities
              .map(
                (amenity) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(amenity, style: AppTextStyles.bodySmall),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRoomTypes() {
    if (_hotel!.roomTypes.isEmpty && _offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Room types', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        if (_hotel!.roomTypes.isNotEmpty)
          ..._hotel!.roomTypes.map((room) => _buildRoomCard(room)),
        if (_offers.isNotEmpty)
          ..._offers.map((offer) => _buildOfferCard(offer)),
      ],
    );
  }

  Widget _buildRoomCard(HotelRoomType room) {
    final image = room.images.isNotEmpty ? room.images.first : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel,
                      size: 32, color: AppColors.primary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name ?? 'Room', style: AppTextStyles.h4),
                if (room.description != null &&
                    room.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(room.description!, style: AppTextStyles.bodySmall),
                ],
                if (room.maxOccupancy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      'Max occupancy: ${room.maxOccupancy} guest${room.maxOccupancy == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall),
                ],
                if (room.bedType != null && room.bedType!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Bed type: ${room.bedType}',
                      style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(HotelOffer offer) {
    final image = offer.images.isNotEmpty ? offer.images.first : null;
    final total = offer.price + offer.taxes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel,
                      size: 32, color: AppColors.primary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.roomName, style: AppTextStyles.h4),
                if (offer.description != null &&
                    offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(offer.description!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
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
                    const Spacer(),
                    Text(
                      '£${total.toStringAsFixed(0)} total',
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
                if (offer.refundable) ...[
                  const SizedBox(height: 8),
                  const Text('Free cancellation',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _reserve(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('Reserve room'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reserve(BuildContext context) {
    if (_hotel == null) return;
    final encodedName = Uri.encodeComponent(_hotel!.name);
    context.push('/hotels/${_hotel!.id}/rooms?hotelName=$encodedName',
        extra: widget.criteria);
  }
}
