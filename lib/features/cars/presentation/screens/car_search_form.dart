import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class CarSearchForm extends StatefulWidget {
  const CarSearchForm({super.key});

  @override
  State<CarSearchForm> createState() => _CarSearchFormState();
}

class _CarSearchFormState extends State<CarSearchForm> {
  final _pickupController = TextEditingController();
  final _dropOffController = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _dropOffDate;
  int _passengers = 1;

  Future<void> _pickPickupDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _pickDropOffDate() async {
    final now = DateTime.now();
    final initial = _dropOffDate ?? (_pickupDate ?? now).add(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _pickupDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _dropOffDate = picked);
    }
  }

  void _searchCars() {
    if (_pickupController.text.trim().isEmpty ||
        _dropOffController.text.trim().isEmpty ||
        _pickupDate == null ||
        _dropOffDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Car search coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _pickupController,
            decoration: const InputDecoration(
              labelText: 'Pickup location',
              hintText: 'City or airport',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickPickupDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Pickup date'),
              child: Text(
                _pickupDate == null
                    ? 'Select date'
                    : '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dropOffController,
            decoration: const InputDecoration(
              labelText: 'Drop-off location',
              hintText: 'City or airport',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDropOffDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Drop-off date'),
              child: Text(
                _dropOffDate == null
                    ? 'Select date'
                    : '${_dropOffDate!.day}/${_dropOffDate!.month}/${_dropOffDate!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Passengers', style: AppTextStyles.bodyLarge),
              const Spacer(),
              IconButton(
                onPressed: _passengers > 1
                    ? () => setState(() => _passengers--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_passengers', style: AppTextStyles.h3),
              IconButton(
                onPressed: _passengers < 8
                    ? () => setState(() => _passengers++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Search cars',
            onPressed: _searchCars,
          ),
        ],
      ),
    );
  }
}
