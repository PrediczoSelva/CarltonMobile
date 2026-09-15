import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.criteria,
  });

  final CarVehicle car;
  final CarSearchCriteria criteria;

  @override
  Widget build(BuildContext context) {
    final days = criteria.rentalDays;
    final totalPrice = car.dailyPrice * days;

    return Scaffold(
      appBar: AppBar(
        title: Text(car.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildImageCarousel(),
          const SizedBox(height: 16),
          Text(car.name, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('${car.category} · ${car.companyName}',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (car.rating > 0) ...[
                const Icon(Icons.star, size: 18, color: AppColors.accent),
                Text(' ${car.rating.toStringAsFixed(1)} (${car.reviewCount} reviews)',
                    style: AppTextStyles.bodyMedium),
              ],
              const Spacer(),
              Text('£${car.dailyPrice.toStringAsFixed(0)} / day',
                  style: AppTextStyles.price),
            ],
          ),
          const SizedBox(height: 4),
          Text('Total £${totalPrice.toStringAsFixed(0)} for $days ${days > 1 ? 'days' : 'day'}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (car.freeCancellation) ...[
            const SizedBox(height: 8),
            const Text('Free cancellation',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          Text('Specifications', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildSpecGrid(),
          const SizedBox(height: 24),
          if (car.mileagePolicy.isNotEmpty) ...[
            Text('Mileage policy', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(car.mileagePolicy, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
          ],
          if (car.includedFeatures.isNotEmpty) ...[
            Text('Included features', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: car.includedFeatures
                  .map((feature) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(feature, style: AppTextStyles.bodySmall),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          Center(
            child: SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Reserve now',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking flow for ${car.name} coming soon.')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = car.images.where((img) => img.isNotEmpty).toList();

    if (images.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.directions_car,
            size: 64, color: AppColors.primary),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              images[index],
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.directions_car,
                    size: 48, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecGrid() {
    final specs = <Map<String, dynamic>>[
      if (car.seats > 0) {'icon': Icons.chair, 'label': '${car.seats} seats'},
      if (car.doors > 0) {'icon': Icons.door_front_door_outlined, 'label': '${car.doors} doors'},
      {'icon': Icons.drive_eta, 'label': car.transmission},
      {'icon': Icons.local_gas_station_outlined, 'label': car.fuelType},
      if (car.airConditioning) {'icon': Icons.ac_unit, 'label': 'Air conditioning'},
      if (car.unlimitedMileage) {'icon': Icons.speed, 'label': 'Unlimited mileage'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final spec = specs[index];
        return Row(
          children: [
            Icon(spec['icon'] as IconData, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(spec['label'] as String, style: AppTextStyles.bodyMedium),
          ],
        );
      },
    );
  }
}
