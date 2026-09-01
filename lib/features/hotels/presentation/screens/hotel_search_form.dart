import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class HotelSearchForm extends StatefulWidget {
  const HotelSearchForm({super.key});

  @override
  State<HotelSearchForm> createState() => _HotelSearchFormState();
}

class _HotelSearchFormState extends State<HotelSearchForm> {
  final _destinationController = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _checkIn = picked);
    }
  }

  Future<void> _pickCheckOut() async {
    final now = DateTime.now();
    final initial = _checkOut ?? (_checkIn ?? now).add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _checkIn ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _checkOut = picked);
    }
  }

  void _searchHotels() {
    if (_destinationController.text.trim().isEmpty || _checkIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hotel search coming soon')),
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
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'City or hotel name',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickCheckIn,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Check-in'),
              child: Text(
                _checkIn == null
                    ? 'Select date'
                    : '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickCheckOut,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Check-out'),
              child: Text(
                _checkOut == null
                    ? 'Select date'
                    : '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Rooms', style: AppTextStyles.bodyLarge),
              const Spacer(),
              IconButton(
                onPressed: _rooms > 1
                    ? () => setState(() => _rooms--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_rooms', style: AppTextStyles.h3),
              IconButton(
                onPressed: () => setState(() => _rooms++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Adults', style: AppTextStyles.bodyLarge),
              const Spacer(),
              IconButton(
                onPressed: _adults > 1
                    ? () => setState(() => _adults--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_adults', style: AppTextStyles.h3),
              IconButton(
                onPressed: _adults < 10
                    ? () => setState(() => _adults++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Children', style: AppTextStyles.bodyLarge),
              const Spacer(),
              IconButton(
                onPressed: _children > 0
                    ? () => setState(() => _children--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_children', style: AppTextStyles.h3),
              IconButton(
                onPressed: _children < 10
                    ? () => setState(() => _children++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Search hotels',
            onPressed: _searchHotels,
          ),
        ],
      ),
    );
  }
}
