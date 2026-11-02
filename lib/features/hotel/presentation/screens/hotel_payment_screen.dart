import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class HotelPaymentScreen extends StatefulWidget {
  const HotelPaymentScreen({super.key});

  @override
  State<HotelPaymentScreen> createState() => _HotelPaymentScreenState();
}

class _HotelPaymentScreenState extends State<HotelPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _cardholder = TextEditingController();
  final _paypalEmail = TextEditingController();
  final _session = getIt<BookingSession>();
  String _method = 'card';

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _cardholder.dispose();
    _paypalEmail.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter $label' : null;

  String? _cardNumberValidator(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return 'Enter card number';
    if (digits.length < 13 || digits.length > 19) {
      return 'Enter a valid card number';
    }
    return null;
  }

  String? _expiryValidator(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(text)) return 'Use MM/YY format';
    final month = int.tryParse(text.substring(0, 2)) ?? 0;
    if (month < 1 || month > 12) return 'Enter a valid expiry date';
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter PayPal email';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address';
  }

  void _confirmPayment() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _session.paymentMethod = _method;
    _session.hotelPaymentLast4 = _method == 'card'
        ? _cardNumber.text.replaceAll(RegExp(r'\D'), '').substring(
            _cardNumber.text.replaceAll(RegExp(r'\D'), '').length - 4)
        : null;
    _session.hotelBookingReference =
        'HTL-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    _session.bookingReference = _session.hotelBookingReference;
    _session.bookingStatus = 'Confirmed';
    context.push('/hotels/confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final total = _session.totalPrice ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Amount to pay',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textOnPrimary),
                      ),
                    ),
                    Text(
                      '£${total.toStringAsFixed(2)}',
                      style: AppTextStyles.h2
                          .copyWith(color: AppColors.textOnPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Choose payment method', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            ...[
              ('card', 'Credit or debit card', Icons.credit_card),
              ('paypal', 'PayPal', Icons.account_balance_wallet_outlined),
              ('wallet', 'Carlton Wallet', Icons.wallet_outlined),
            ].map(
              (method) => RadioListTile<String>(
                value: method.$1,
                groupValue: _method,
                onChanged: (value) => setState(() => _method = value!),
                title: Row(
                  children: [
                    Icon(method.$3, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(method.$2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_method == 'card') _buildCardFields(),
            if (_method == 'paypal')
              TextFormField(
                controller: _paypalEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'PayPal email'),
                validator: _emailValidator,
              ),
            if (_method == 'wallet')
              Card(
                color: AppColors.surfaceVariant,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Your Carlton Wallet balance will be checked when you confirm payment.'),
                ),
              ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Confirm payment', onPressed: _confirmPayment),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cardholder,
          decoration: const InputDecoration(labelText: 'Cardholder name'),
          validator: (value) => _required(value, 'cardholder name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Card number'),
          validator: _cardNumberValidator,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiry,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                validator: _expiryValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'CVV'),
                validator: (value) {
                  final digits = value ?? '';
                  return digits.length >= 3 && digits.length <= 4
                      ? null
                      : 'Enter a valid CVV';
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
