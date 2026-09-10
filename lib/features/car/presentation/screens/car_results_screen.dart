import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarSearchResultArgs {
  const CarSearchResultArgs({required this.criteria, required this.cars});
  final CarSearchCriteria criteria;
  final List<CarVehicle> cars;
}

class CarResultsScreen extends StatefulWidget {
  const CarResultsScreen({super.key, required this.args});
  final CarSearchResultArgs args;
  @override
  State<CarResultsScreen> createState() => _CarResultsScreenState();
}

class _CarResultsScreenState extends State<CarResultsScreen> {
  String _sort = 'recommended';
  bool _freeCancellation = false;

  List<CarVehicle> get _cars {
    final cars = widget.args.cars
        .where((car) => !_freeCancellation || car.freeCancellation)
        .toList();
    switch (_sort) {
      case 'price_low':
        cars.sort((a, b) => a.dailyPrice.compareTo(b.dailyPrice));
      case 'price_high':
        cars.sort((a, b) => b.dailyPrice.compareTo(a.dailyPrice));
      case 'rating':
        cars.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return cars;
  }

  @override
  Widget build(BuildContext context) {
    final cars = _cars;
    final criteria = widget.args.criteria;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car results'),
        actions: [
          Center(
              child: Text('${cars.length} found',
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
                        '${criteria.pickupLocation} · ${criteria.rentalDays} day${criteria.rentalDays == 1 ? '' : 's'}',
                        style: AppTextStyles.h4)),
                IconButton(
                    tooltip: 'Modify search',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.edit_outlined)),
              ],
            ),
          ),
          SingleChildScrollView(
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
                        value: 'price_low', child: Text('Lowest price')),
                    DropdownMenuItem(
                        value: 'price_high', child: Text('Highest price')),
                    DropdownMenuItem(
                        value: 'rating', child: Text('Best rated')),
                  ],
                  onChanged: (value) =>
                      setState(() => _sort = value ?? 'recommended'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                    label: const Text('Free cancellation'),
                    selected: _freeCancellation,
                    onSelected: (value) =>
                        setState(() => _freeCancellation = value)),
              ],
            ),
          ),
          Expanded(
            child: cars.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: cars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _CarCard(car: cars[index], days: criteria.rentalDays),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No cars found', style: AppTextStyles.h4),
            TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.search),
                label: const Text('Modify search')),
          ],
        ),
      );
}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.days});
  final CarVehicle car;
  final int days;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (car.images.isNotEmpty)
              Image.network(car.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback())
            else
              _fallback(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: AppTextStyles.h4),
                  Text('${car.category} · ${car.companyName}',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 6, children: [
                    Text('${car.seats} seats'),
                    Text('${car.doors} doors'),
                    Text(car.transmission),
                    Text(car.fuelType)
                  ]),
                  const SizedBox(height: 8),
                  Text(car.includedFeatures.take(3).join(' · '),
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (car.rating > 0) ...[
                      const Icon(Icons.star, size: 17, color: AppColors.accent),
                      Text(' ${car.rating.toStringAsFixed(1)}')
                    ],
                    const Spacer(),
                    Text('GBP ${car.dailyPrice.toStringAsFixed(0)} / day',
                        style: AppTextStyles.price),
                  ]),
                  Text(
                      'Estimated total GBP ${(car.dailyPrice * days).toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall),
                  if (car.freeCancellation)
                    const Text('Free cancellation',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _fallback() => Container(
      height: 150,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child:
          const Icon(Icons.directions_car, size: 52, color: AppColors.primary));
}
