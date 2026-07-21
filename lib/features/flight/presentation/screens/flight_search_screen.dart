import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _fromController = TextEditingController(text: 'Colombo (CMB)');
  final _toController = TextEditingController(text: 'London (LHR)');
  DateTime? _departure;
  DateTime? _return;
  int _passengers = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? now : (_return ?? now).add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDeparture) {
          _departure = picked;
        } else {
          _return = picked;
        }
      });
    }
  }

  Future<void> _searchFlights() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.push('/flights/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search flights')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _fromController,
                decoration: const InputDecoration(labelText: 'From', hintText: 'City or airport'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _toController,
                decoration: const InputDecoration(labelText: 'To', hintText: 'City or airport'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isDeparture: true),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Departure'),
                  child: Text(
                    _departure == null
                        ? 'Select date'
                        : '${_departure!.day}/${_departure!.month}/${_departure!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isDeparture: false),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Return'),
                  child: Text(
                    _return == null
                        ? 'Optional'
                        : '${_return!.day}/${_return!.month}/${_return!.year}',
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
                    onPressed: _passengers < 9
                        ? () => setState(() => _passengers++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Search flights', isLoading: _isLoading, onPressed: _searchFlights),
            ],
          ),
        ),
      ),
    );
  }
}
