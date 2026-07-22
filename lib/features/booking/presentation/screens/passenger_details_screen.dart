import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  int _passengerCount = 1;

  final List<Map<String, TextEditingController>> _passengers = [
    {
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'dob': TextEditingController(),
      'nationality': TextEditingController(),
      'passportNumber': TextEditingController(),
      'passportExpiry': TextEditingController(),
    }
  ];

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController(text: 'Sri Lanka');
  bool _isLoading = false;

  @override
  void dispose() {
    for (final passenger in _passengers) {
      for (final controller in passenger.values) {
        controller.dispose();
      }
    }
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _addPassenger() {
    setState(() {
      _passengerCount++;
      _passengers.add({
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'dob': TextEditingController(),
        'nationality': TextEditingController(),
        'passportNumber': TextEditingController(),
        'passportExpiry': TextEditingController(),
      });
    });
  }

  Future<void> _next() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
      context.push('/booking/summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildPassengerForms(),
              const SizedBox(height: 12),
              if (_passengerCount < 9)
                OutlinedButton.icon(
                  onPressed: _addPassenger,
                  icon: const Icon(Icons.add),
                  label: Text('Add passenger $_passengerCount'),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Contact details', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country of residence'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Continue', isLoading: _isLoading, onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPassengerForms() {
    final widgets = <Widget>[];
    for (var i = 0; i < _passengers.length; i++) {
      final passenger = _passengers[i];
      final lead = i == 0;
      widgets.addAll([
        Row(
          children: [
            Text(lead ? 'Lead passenger' : 'Passenger ${i + 1}', style: AppTextStyles.h4),
            if (lead) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Lead', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnAccent)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passenger['firstName'],
          decoration: const InputDecoration(labelText: 'First name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passenger['lastName'],
          decoration: const InputDecoration(labelText: 'Last name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passenger['dob'],
          decoration: const InputDecoration(labelText: 'Date of birth'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Passenger type'),
                items: const [
                  DropdownMenuItem(value: 'Adult', child: Text('Adult')),
                  DropdownMenuItem(value: 'Child', child: Text('Child')),
                  DropdownMenuItem(value: 'Infant', child: Text('Infant')),
                ],
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: passenger['nationality'],
                decoration: const InputDecoration(labelText: 'Nationality'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passenger['passportNumber'],
          decoration: const InputDecoration(labelText: 'Passport number'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passenger['passportExpiry'],
          decoration: const InputDecoration(labelText: 'Passport expiry'),
        ),
        const SizedBox(height: 20),
      ]);
    }
    return widgets;
  }
}
