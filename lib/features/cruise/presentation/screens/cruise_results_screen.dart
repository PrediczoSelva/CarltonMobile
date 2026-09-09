import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/cruise.dart';
import '../../domain/entities/cruise_search_criteria.dart';

class CruiseSearchResultArgs {
  const CruiseSearchResultArgs({required this.criteria, required this.cruises});

  final CruiseSearchCriteria criteria;
  final List<Cruise> cruises;
}

class CruiseResultsScreen extends StatefulWidget {
  const CruiseResultsScreen({super.key, required this.args});

  final CruiseSearchResultArgs args;

  @override
  State<CruiseResultsScreen> createState() => _CruiseResultsScreenState();
}

class _CruiseResultsScreenState extends State<CruiseResultsScreen> {
  String _sort = 'recommended';
  double _maximumPrice = 5000;
  bool _allInclusiveOnly = false;

  List<Cruise> get _cruises {
    final filtered = widget.args.cruises.where((cruise) {
      if (cruise.startingPrice > _maximumPrice) {
        return false;
      }
      if (_allInclusiveOnly &&
          !cruise.tags.any((tag) => tag.toLowerCase().contains('inclusive'))) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case 'price-asc':
        filtered.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
      case 'price-desc':
        filtered.sort((a, b) => b.startingPrice.compareTo(a.startingPrice));
      case 'duration-asc':
        filtered.sort((a, b) => a.durationNights.compareTo(b.durationNights));
      case 'duration-desc':
        filtered.sort((a, b) => b.durationNights.compareTo(a.durationNights));
      case 'rating-desc':
        filtered.sort((a, b) => b.shipRating.compareTo(a.shipRating));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final criteria = widget.args.criteria;
    final cruises = _cruises;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cruise results'),
        actions: [
          Center(
              child: Text('${cruises.length} found',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white))),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${criteria.destination.isEmpty ? 'All available' : criteria.destination} cruises · ${criteria.guests} guests · ${criteria.cabinsCount} cabin${criteria.cabinsCount > 1 ? 's' : ''}',
                    style: AppTextStyles.h4,
                  ),
                ),
                IconButton(
                    tooltip: 'Modify search',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.edit_outlined)),
              ],
            ),
          ),
          _buildControls(),
          Expanded(
            child: cruises.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: cruises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _CruiseCard(cruise: cruises[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
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
                  value: 'price-asc', child: Text('Price: low to high')),
              DropdownMenuItem(
                  value: 'price-desc', child: Text('Price: high to low')),
              DropdownMenuItem(
                  value: 'duration-asc', child: Text('Shortest duration')),
              DropdownMenuItem(
                  value: 'duration-desc', child: Text('Longest duration')),
              DropdownMenuItem(
                  value: 'rating-desc', child: Text('Highest rating')),
            ],
            onChanged: (value) =>
                setState(() => _sort = value ?? 'recommended'),
          ),
          const SizedBox(width: 8),
          FilterChip(
              label: const Text('All-inclusive'),
              selected: _allInclusiveOnly,
              onSelected: (value) => setState(() => _allInclusiveOnly = value)),
          const SizedBox(width: 8),
          SizedBox(
            width: 180,
            child: Row(children: [
              const Text('Max'),
              Expanded(
                  child: Slider(
                      value: _maximumPrice,
                      min: 400,
                      max: 5000,
                      divisions: 46,
                      label: '£${_maximumPrice.toStringAsFixed(0)}',
                      onChanged: (value) =>
                          setState(() => _maximumPrice = value))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.directions_boat_outlined,
            size: 52, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text('No cruises found', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        const Text('Try changing your destination, port, or filters.'),
        TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.search),
            label: const Text('Modify search')),
      ]));
}

class _CruiseCard extends StatelessWidget {
  const _CruiseCard({required this.cruise});

  final Cruise cruise;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (cruise.heroImage.isNotEmpty)
          Image.network(cruise.heroImage,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback())
        else
          _fallback(),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${cruise.cruiseLine} · ${cruise.shipName}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(cruise.title, style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text('${cruise.departurePort} → ${cruise.returnPort}',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(
                '${cruise.durationNights} nights · ${cruise.departureDates.isEmpty ? 'Date to be confirmed' : cruise.departureDates.first}',
                style: AppTextStyles.bodySmall),
            if (cruise.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(cruise.tags.take(3).join(' · '),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.success)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.star, size: 17, color: AppColors.accent),
              Text(
                  ' ${cruise.shipRating.toStringAsFixed(1)} (${cruise.reviewsCount} reviews)'),
              const Spacer(),
              Text('£${cruise.startingPrice.toStringAsFixed(0)} / person',
                  style: AppTextStyles.price),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _fallback() => Container(
      height: 170,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Icon(Icons.directions_boat,
          size: 56, color: AppColors.primary));
}
