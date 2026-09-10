import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';

class HotelSearchResultArgs {
  const HotelSearchResultArgs({required this.criteria, required this.hotels});

  final HotelSearchCriteria criteria;
  final List<Hotel> hotels;
}

class HotelResultsScreen extends StatefulWidget {
  const HotelResultsScreen({super.key, required this.args});

  final HotelSearchResultArgs args;

  @override
  State<HotelResultsScreen> createState() => _HotelResultsScreenState();
}

class _HotelResultsScreenState extends State<HotelResultsScreen> {
  String _sort = 'recommended';
  bool _freeCancellationOnly = false;
  int? _minimumStars;

  List<Hotel> get _hotels {
    final filtered = widget.args.hotels.where((hotel) {
      if (_freeCancellationOnly && !hotel.refundable) return false;
      if (_minimumStars != null && hotel.starRating < _minimumStars!) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case 'rating':
        filtered.sort((a, b) => b.guestRating.compareTo(a.guestRating));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final criteria = widget.args.criteria;
    final hotels = _hotels;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel results'),
        actions: [
          if (widget.args.hotels.isNotEmpty)
            Center(
                child: Text('${hotels.length} found',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white))),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(criteria),
          _buildFilters(),
          Expanded(
            child: hotels.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: hotels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _HotelCard(hotel: hotels[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(HotelSearchCriteria criteria) {
    final dateFormat = DateFormat('d MMM');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(criteria.destination, style: AppTextStyles.h4),
                Text(
                  '${dateFormat.format(criteria.checkIn)} - ${dateFormat.format(criteria.checkOut)} · ${criteria.nights} nights · ${criteria.guests} guests · ${criteria.rooms} room${criteria.rooms > 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Modify search',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _sort,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                  value: 'recommended', child: Text('Recommended')),
              DropdownMenuItem(
                  value: 'price_low', child: Text('Price: low to high')),
              DropdownMenuItem(
                  value: 'price_high', child: Text('Price: high to low')),
              DropdownMenuItem(value: 'rating', child: Text('Guest rating')),
            ],
            onChanged: (value) =>
                setState(() => _sort = value ?? 'recommended'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Free cancellation'),
            selected: _freeCancellationOnly,
            onSelected: (value) =>
                setState(() => _freeCancellationOnly = value),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('4+ stars'),
            selected: _minimumStars == 4,
            onSelected: (value) =>
                setState(() => _minimumStars = value ? 4 : null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hotel_outlined,
              size: 52, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('No hotels found', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          const Text('Try changing your dates or filters.'),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.search),
            label: const Text('Modify search'),
          ),
        ],
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel});

  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hotel.thumbnail != null && hotel.thumbnail!.isNotEmpty)
            Image.network(
              hotel.thumbnail!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            )
          else
            _imageFallback(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.name,
                    style: AppTextStyles.h4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(hotel.location,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (hotel.starRating > 0) ...[
                      const Icon(Icons.star, size: 17, color: AppColors.accent),
                      Text(' ${hotel.starRating} stars'),
                    ],
                    if (hotel.guestRating > 0) ...[
                      const SizedBox(width: 12),
                      Text('Guest ${hotel.guestRating.toStringAsFixed(1)}'),
                    ],
                    const Spacer(),
                    Text(
                      '£${hotel.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
                if (hotel.refundable) ...[
                  const SizedBox(height: 8),
                  const Text('Free cancellation',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
                if (hotel.amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(hotel.amenities.take(3).join(' · '),
                      style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Icon(Icons.hotel, size: 52, color: AppColors.primary),
    );
  }
}
