import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarExtrasScreen extends StatefulWidget {
  const CarExtrasScreen({
    super.key,
    required this.car,
    required this.criteria,
  });

  final CarVehicle car;
  final CarSearchCriteria criteria;

  @override
  State<CarExtrasScreen> createState() => _CarExtrasScreenState();
}

class _CarExtrasScreenState extends State<CarExtrasScreen> {
  final Set<int> _selectedExtras = {};

  static const _extras = [
    _CarExtra(
      title: 'Full protection',
      description: 'Reduce your excess and travel with complete peace of mind.',
      price: 18,
      icon: Icons.shield_outlined,
    ),
    _CarExtra(
      title: 'Additional driver',
      description: 'Let another registered driver share the driving.',
      price: 9,
      icon: Icons.person_add_alt_1_outlined,
    ),
    _CarExtra(
      title: 'Child seat',
      description: 'A child seat supplied by the rental company.',
      price: 7,
      icon: Icons.child_friendly_outlined,
    ),
    _CarExtra(
      title: 'Roadside assistance',
      description: 'Extra support in the event of a breakdown or puncture.',
      price: 6,
      icon: Icons.car_repair_outlined,
    ),
  ];

  double get _carTotal => widget.car.dailyPrice * widget.criteria.rentalDays;

  double get _extrasTotal =>
      _selectedExtras.fold<double>(
          0, (total, index) => total + _extras[index].price) *
      widget.criteria.rentalDays;

  double get _total => _carTotal + _extrasTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add-ons & extras')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('Optional equipment and protection from the rental company',
              style: AppTextStyles.bodyLarge),
          const SizedBox(height: 20),
          _buildCarSummary(),
          const SizedBox(height: 24),
          Text('Choose your extras', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...List.generate(_extras.length, (index) {
            final extra = _extras[index];
            final selected = _selectedExtras.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExtraCard(
                extra: extra,
                selected: selected,
                days: widget.criteria.rentalDays,
                onChanged: (value) => setState(() {
                  if (value) {
                    _selectedExtras.add(index);
                  } else {
                    _selectedExtras.remove(index);
                  }
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
          _buildPriceSummary(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Continue to guest details',
            onPressed: () => context.push('/car-search/checkout/guest', extra: {
              'car': widget.car,
              'criteria': widget.criteria,
              'total': _total,
              'extras':
                  _selectedExtras.map((index) => _extras[index].title).toList(),
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCarSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _carImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.car.name, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('${widget.car.category} · ${widget.car.companyName}',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.criteria.rentalDays} day${widget.criteria.rentalDays == 1 ? '' : 's'} · ${widget.criteria.pickupLocation}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carImage() {
    final image = widget.car.images.isEmpty ? null : widget.car.images.first;
    if (image == null) {
      return _imageFallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(image,
          width: 92,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback()),
    );
  }

  Widget _imageFallback() => Container(
        width: 92,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_car, color: AppColors.primary),
      );

  Widget _buildPriceSummary() => Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _summaryRow('Car rental', _carTotal),
              _summaryRow('Add-ons & extras', _extrasTotal),
              const Divider(height: 24),
              Row(
                children: [
                  Text('Estimated total', style: AppTextStyles.h4),
                  const Spacer(),
                  Text('£${_total.toStringAsFixed(2)}',
                      style: AppTextStyles.price),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _summaryRow(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Text('£${value.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      );
}

class _CarExtra {
  const _CarExtra({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
  });

  final String title;
  final String description;
  final double price;
  final IconData icon;
}

class _ExtraCard extends StatelessWidget {
  const _ExtraCard({
    required this.extra,
    required this.selected,
    required this.days,
    required this.onChanged,
  });

  final _CarExtra extra;
  final bool selected;
  final int days;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        secondary: Icon(extra.icon, color: AppColors.primary, size: 28),
        title: Text(extra.title,
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              '${extra.description}\n£${extra.price.toStringAsFixed(2)} per day',
              style: AppTextStyles.bodySmall),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
