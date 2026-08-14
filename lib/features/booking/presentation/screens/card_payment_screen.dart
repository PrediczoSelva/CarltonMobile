import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../payment/domain/repositories/payment_repository.dart';

class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillCardholderName();
  }

  Future<void> _prefillCardholderName() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      if (mounted && user.name.isNotEmpty) {
        _nameController.text = user.name;
      }
    } catch (_) {
      // Not logged in or no stored user; leave the field blank.
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.isEmpty) return 'Card number is required';
    if (cleaned.length < 13 || cleaned.length > 19)
      return 'Card number must be 13-19 digits';
    if (!_luhnCheck(cleaned)) return 'Invalid card number';
    return null;
  }

  String? _validateExpiry(String value) {
    final cleaned = value.replaceAll('/', '');
    if (cleaned.isEmpty) return 'Expiry is required';
    if (cleaned.length != 4) return 'Use MM/YY format';
    final month = int.tryParse(cleaned.substring(0, 2));
    final year = int.tryParse(cleaned.substring(2, 4));
    if (month == null || year == null || month < 1 || month > 12)
      return 'Invalid month';
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }
    return null;
  }

  String? _validateCvv(String value) {
    if (value.isEmpty) return 'CVV is required';
    if (value.length < 3 || value.length > 4) return 'CVV must be 3-4 digits';
    return null;
  }

  bool _luhnCheck(String number) {
    var sum = 0;
    var alternate = false;
    for (var i = number.length - 1; i >= 0; i--) {
      var n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  Future<void> _pay() async {
    setState(() => _error = null);

    final nameError = _nameController.text.trim().isEmpty
        ? 'Cardholder name is required'
        : null;
    final cardError = _validateCardNumber(_cardNumberController.text);
    final expiryError = _validateExpiry(_expiryController.text);
    final cvvError = _validateCvv(_cvvController.text);

    if (nameError != null ||
        cardError != null ||
        expiryError != null ||
        cvvError != null) {
      setState(
          () => _error = nameError ?? cardError ?? expiryError ?? cvvError);
      return;
    }

    if (Stripe.publishableKey.isEmpty) {
      setState(() => _error =
          'Stripe is not configured. Please provide a Stripe publishable key.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = getIt<BookingSession>();
      final flight = session.selectedOutboundFlight;
      if (flight == null) {
        throw Exception('No flight selected. Please go back and search again.');
      }

      final amount = session.totalPriceWithTaxes;

      if (amount < 0.50) {
        throw Exception(
            'The selected flight price is too low to process payment. Please select a different flight.');
      }

      final source = flight.source.toLowerCase();
      final isAtlas = source.contains('atlas');
      final isAmadeus = source.contains('amadeus');
      final isTravelport = source.contains('travelport');
      final isProviderFlight = isAtlas || isAmadeus || isTravelport;

      if (!isProviderFlight) {
        throw Exception(
            'Only provider flights are supported. Please search and select a provider flight.');
      }

      final bookingKey = flight.bookingKey?.trim().isEmpty == false
          ? flight.bookingKey!.trim()
          : flight.providerOfferId?.trim().isEmpty == false
              ? flight.providerOfferId!.trim()
              : null;

      if (bookingKey == null) {
        throw Exception(
            'This flight is missing booking details. Please go back and search again.');
      }

      debugPrint(
          '[CardPayment] flight=${flight.flightCode} source=${flight.source} id=${flight.id} amount=$amount');

      String? stripeIntentId;
      String? paymentStatus;

      if (isProviderFlight) {
        stripeIntentId = null;
        paymentStatus = null;
      } else {
        final paymentRepository = getIt<PaymentRepository>();
        final paymentIntent = await paymentRepository.createFlightPaymentIntent(
          flightId: flight.id,
          amount: amount,
          summary: 'Carlton flight booking (flight ${flight.flightCode})',
        );

        if (paymentIntent.clientSecret.isEmpty) {
          throw Exception('Unable to create payment session. Please try again.');
        }

        final expiryParts = _expiryController.text.split('/');
        final expiryMonth = int.parse(expiryParts[0]);
        final expiryYear = int.parse('20${expiryParts[1]}');

        await Stripe.instance.dangerouslyUpdateCardDetails(
          CardDetails(
            number: _cardNumberController.text.replaceAll(' ', ''),
            expirationMonth: expiryMonth,
            expirationYear: expiryYear,
            cvc: _cvvController.text,
          ),
        );

        final confirmedIntent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          data: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: _nameController.text.trim(),
              ),
            ),
          ),
        );

        stripeIntentId = confirmedIntent.id;
        paymentStatus = 'succeeded';
      }

      final lastFour = _cardNumberController.text.replaceAll(' ', '').substring(
            _cardNumberController.text.replaceAll(' ', '').length - 4,
          );

      final paymentMetadata = {
        'paymentMethod': 'card',
        'paymentStatus': paymentStatus ?? 'pending',
        'stripePaymentIntentId': stripeIntentId ?? '',
        'paidAtUtc': DateTime.now().toUtc().toIso8601String(),
        'lastFour': lastFour,
        'cardHolderType': 'lead',
        'billingType': 'same',
        'contactPhone': session.contactPhone ?? '',
        'contactCountry': session.contactCountry ?? '',
        'guestCheckout': false,
        'contactEmail': session.contactEmail ?? '',
      };

      session.paymentMetadataJson = jsonEncode(paymentMetadata);
      session.stripePaymentIntentId = stripeIntentId;
      session.paymentMethod = 'card';

      if (mounted) {
        context.push('/booking/payment/process');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;
    final currency = session.currency ?? 'GBP';

    return Scaffold(
      appBar: AppBar(title: const Text('Card payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount to pay',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currency ${price.toStringAsFixed(0)}',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_error != null) const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Cardholder name'),
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card number'),
                keyboardType: TextInputType.number,
                inputFormatters: [_CardNumberFormatter()],
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: const InputDecoration(labelText: 'MM/YY'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ExpiryFormatter()],
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      enabled: !_isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isLoading ? 'Processing...' : 'Pay now',
                onPressed: _isLoading ? null : _pay,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : _fillTestCard,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Fill test card'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fillTestCard() {
    if (mounted) {
      setState(() {
        _cardNumberController.text = '4242 4242 4242 4242';
        _expiryController.text = '12/34';
        _cvvController.text = '123';
        _nameController.text = 'Test User';
        _error = null;
      });
    }
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    var formatted = '';
    for (var i = 0; i < min(digits.length, 16); i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    var formatted = '';
    for (var i = 0; i < min(digits.length, 4); i++) {
      if (i == 2) formatted += '/';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
