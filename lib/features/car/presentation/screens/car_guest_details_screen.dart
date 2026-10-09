import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarGuestDetailsScreen extends StatefulWidget {
  const CarGuestDetailsScreen({
    super.key,
    this.car,
    this.criteria,
    this.total,
    this.extras = const [],
  });

  final CarVehicle? car;
  final CarSearchCriteria? criteria;
  final double? total;
  final List<String> extras;

  @override
  State<CarGuestDetailsScreen> createState() => _CarGuestDetailsScreenState();
}

class _CarGuestDetailsScreenState extends State<CarGuestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flightController = TextEditingController();
  String _title = 'Mr';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text('Who is the main driver?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
                'Enter the details exactly as they appear on the driving licence.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Driver details',
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  items: ['Mr', 'Mrs', 'Ms', 'Dr']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _title = value ?? 'Mr'),
                ),
                const SizedBox(height: 12),
                _field(_firstNameController, 'First name'),
                const SizedBox(height: 12),
                _field(_lastNameController, 'Last name'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Contact details',
              children: [
                _field(_emailController, 'Email address',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_phoneController, 'Mobile number',
                    keyboardType: TextInputType.phone),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Collection details',
              children: [
                _field(_flightController, 'Flight number (optional)',
                    required: false),
              ],
            ),
            if (widget.car != null) ...[
              const SizedBox(height: 16),
              _buildSummary(),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continue to payment',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) =>
              value == null || value.trim().isEmpty ? 'Enter $label' : null
          : null,
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final car = widget.car!;
    final days = widget.criteria?.rentalDays ?? 1;
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking summary', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(car.name,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600)),
            Text('$days day${days == 1 ? '' : 's'} · ${car.companyName}',
                style: AppTextStyles.bodySmall),
            if (widget.extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Extras: ${widget.extras.join(', ')}',
                  style: AppTextStyles.bodySmall),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Text('Estimated total', style: AppTextStyles.h4),
                const Spacer(),
                Text(
                    '£${(widget.total ?? car.dailyPrice * days).toStringAsFixed(2)}',
                    style: AppTextStyles.price),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guest details saved.')),
    );
  }
}
