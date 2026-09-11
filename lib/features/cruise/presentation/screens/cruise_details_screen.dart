import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/cruise.dart';

class CruiseDetailsScreen extends StatelessWidget {
  const CruiseDetailsScreen({
    super.key,
    required this.cruise,
  });

  final Cruise cruise;

  @override
  Widget build(BuildContext context) {
    final dateFormat = cruise.departureDates.isNotEmpty
        ? cruise.departureDates.first
        : 'Date to be confirmed';

    return Scaffold(
      appBar: AppBar(
        title: Text(cruise.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (cruise.heroImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                cruise.heroImage,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.directions_boat,
                      size: 64, color: AppColors.primary),
                ),
              ),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.directions_boat,
                  size: 64, color: AppColors.primary),
            ),
          const SizedBox(height: 16),
          Text('${cruise.cruiseLine} · ${cruise.shipName}',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(cruise.title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${cruise.departurePort} → ${cruise.returnPort}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$dateFormat · ${cruise.durationNights} nights',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: AppColors.accent),
              Text(
                  ' ${cruise.shipRating.toStringAsFixed(1)} (${cruise.reviewsCount} reviews)',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (cruise.overview.isNotEmpty) ...[
            Text('Overview', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(cruise.overview, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
          ],
          if (cruise.highlights.isNotEmpty) ...[
            Text('Highlights', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            ...cruise.highlights.map((highlight) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outlined,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(highlight, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (cruise.inclusions.isNotEmpty) ...[
            Text('Inclusions', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cruise.inclusions
                  .map((inclusion) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(inclusion, style: AppTextStyles.bodySmall),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text('Cabins & details', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildCabinCard(
            context,
            title: 'Interior cabin',
            description: 'Cozy cabin with modern amenities, perfect for relaxing after a day of exploration.',
            price: cruise.startingPrice,
            features: ['Queen bed', 'Private bathroom', 'Mini-bar', 'TV', 'Safe'],
          ),
          const SizedBox(height: 12),
          _buildCabinCard(
            context,
            title: 'Ocean view cabin',
            description: 'Spacious cabin with a large window offering stunning ocean views.',
            price: cruise.startingPrice * 1.25,
            features: ['Queen bed', 'Private bathroom', 'Mini-bar', 'TV', 'Safe', 'Ocean view'],
          ),
          const SizedBox(height: 12),
          _buildCabinCard(
            context,
            title: 'Balcony suite',
            description: 'Luxurious suite with private balcony and premium amenities.',
            price: cruise.startingPrice * 1.6,
            features: ['King bed', 'Private bathroom', 'Mini-bar', 'TV', 'Safe', 'Private balcony', 'Butler service'],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Book now',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking flow for ${cruise.title} coming soon.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCabinCard(
    BuildContext context, {
    required String title,
    required String description,
    required double price,
    required List<String> features,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTextStyles.h4),
                ),
                Text(
                  '£${price.toStringAsFixed(0)} / person',
                  style: AppTextStyles.price,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map((feature) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(feature, style: AppTextStyles.bodySmall),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
