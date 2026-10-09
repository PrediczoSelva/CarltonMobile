import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

class CarPaymentScreen extends StatefulWidget {
  const CarPaymentScreen({
    super.key,
    this.car,
    this.criteria,
    this.total,
    this.extras = const [],
    this.guest = const {},
  });

  final CarVehicle? car;
  final CarSearchCriteria? criteria;
  final double? total;
  final List<String> extras;
  final Map<String, String> guest;

  @override
  State<CarPaymentScreen> createState() => _CarPaymentScreenState();
}

class _CarPaymentScreenState extends State<CarPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.total ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text('Secure payment', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Complete your car rental reservation securely.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _buildBookingSummary(total),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card details', style: AppTextStyles.h4),
                    const SizedBox(height: 14),
                    _field(
                      _nameController,
                      'Name on card',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _cardNumberController,
                      'Card number',
                      keyboardType: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(19),
                      ],
                      validator: _validateCardNumber,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _expiryController,
                            'Expiry (MM/YY)',
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9/]')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            validator: _validateExpiry,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _cvvController,
                            'CVV',
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value == null || value.length < 3) {
                                return 'Enter CVV';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment details are encrypted and secure.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Pay £${total.toStringAsFixed(2)}',
              isLoading: _isProcessing,
              onPressed: _pay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (value) =>
              value == null || value.trim().isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildBookingSummary(double total) {
    final car = widget.car;
    final days = widget.criteria?.rentalDays ?? 1;
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order summary', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            if (car != null) ...[
              Text(car.name,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('$days day${days == 1 ? '' : 's'} · ${car.companyName}',
                  style: AppTextStyles.bodySmall),
            ],
            if (widget.extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Extras: ${widget.extras.join(', ')}',
                  style: AppTextStyles.bodySmall),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Text('Total to pay', style: AppTextStyles.h4),
                const Spacer(),
                Text('£${total.toStringAsFixed(2)}',
                    style: AppTextStyles.price),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateCardNumber(String? value) {
    final number = (value ?? '').replaceAll(' ', '');
    if (number.length < 13 || number.length > 19) {
      return 'Enter a valid card number';
    }
    var sum = 0;
    var alternate = false;
    for (var i = number.length - 1; i >= 0; i--) {
      var digit = int.tryParse(number[i]);
      if (digit == null) return 'Enter a valid card number';
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0 ? null : 'Enter a valid card number';
  }

  String? _validateExpiry(String? value) {
    final cleaned = (value ?? '').replaceAll('/', '');
    if (cleaned.length != 4) return 'Use MM/YY';
    final month = int.tryParse(cleaned.substring(0, 2));
    final year = int.tryParse(cleaned.substring(2));
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Invalid expiry';
    }
    final now = DateTime.now();
    if (year < now.year % 100 ||
        (year == now.year % 100 && month < now.month)) {
      return 'Card has expired';
    }
    return null;
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.push('/car-search/confirmation', extra: {
      'car': widget.car,
      'criteria': widget.criteria,
      'total': widget.total,
      'extras': widget.extras,
      'guest': widget.guest,
      'last4': _cardNumberController.text.substring(
          _cardNumberController.text.length - 4),
    });
  }
}
