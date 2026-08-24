import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/wallet_repository.dart';

class TopUpModal extends StatefulWidget {
  const TopUpModal({
    super.key,
    required this.currencyCode,
    required this.onSuccess,
  });

  final String currencyCode;
  final VoidCallback onSuccess;

  @override
  State<TopUpModal> createState() => _TopUpModalState();
}

class _TopUpModalState extends State<TopUpModal> {
  final _customAmountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  int _selectedAmount = 50;
  bool _useCustomAmount = false;
  bool _saveCard = true;
  bool _isLoading = false;
  String? _error;

  final List<int> _quickAmounts = [25, 50, 100, 200];

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
    } catch (_) {}
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double get _finalAmount =>
      _useCustomAmount ? (double.tryParse(_customAmountController.text) ?? 0) : _selectedAmount.toDouble();

  String get _currencySymbol {
    switch (widget.currencyCode.toUpperCase()) {
      case 'LKR':
        return 'Rs.';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      default:
        return '${widget.currencyCode} ';
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  void _handleAmountSelect(int amount) {
    setState(() {
      _selectedAmount = amount;
      _useCustomAmount = false;
      _customAmountController.clear();
    });
  }

  void _handleCustomAmountChange(String value) {
    setState(() {
      _useCustomAmount = true;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);

    if (_finalAmount < 1) {
      setState(() => _error = 'Minimum top-up is ${_formatCurrency(1)}.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter cardholder name.');
      return;
    }

    final cardError = _validateCardNumber(_cardNumberController.text);
    if (cardError != null) {
      setState(() => _error = cardError);
      return;
    }

    final expiryError = _validateExpiry(_expiryController.text);
    if (expiryError != null) {
      setState(() => _error = expiryError);
      return;
    }

    final cvvError = _validateCvv(_cvvController.text);
    if (cvvError != null) {
      setState(() => _error = cvvError);
      return;
    }

    if (Stripe.publishableKey.isEmpty) {
      setState(() => _error = 'Stripe is not configured.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final walletRepository = getIt<WalletRepository>();

      final clientSecret = await walletRepository.createTopUpPaymentIntent(
        amount: _finalAmount,
        currency: widget.currencyCode,
      );

      final paymentIntentId = clientSecret.split('_secret_')[0];

      final expiryParts = _expiryController.text.split('/');
      final expiryMonth = int.parse(expiryParts[0]);
      final expiryYear = 2000 + int.parse(expiryParts[1]);

      await Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails(
          number: _cardNumberController.text.replaceAll(' ', ''),
          expirationMonth: expiryMonth,
          expirationYear: expiryYear,
          cvc: _cvvController.text,
        ),
      );

      final confirmedIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: _nameController.text.trim(),
            ),
          ),
        ),
      );

      if (confirmedIntent.status != PaymentIntentsStatus.Succeeded) {
        throw Exception('Payment confirmation unsuccessful.');
      }

      await walletRepository.confirmTopUp(paymentIntentId: paymentIntentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_formatCurrency(_finalAmount)} added to your wallet!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSuccess();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.isEmpty) return 'Card number is required';
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Card number must be 13-19 digits';
    }
    return null;
  }

  String? _validateExpiry(String value) {
    final cleaned = value.replaceAll('/', '');
    if (cleaned.isEmpty) return 'Expiry is required';
    if (cleaned.length != 4) return 'Use MM/YY format';
    final month = int.tryParse(cleaned.substring(0, 2));
    final year = int.tryParse(cleaned.substring(2, 4));
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Invalid month';
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardPreview(),
                  const SizedBox(height: 20),
                  _buildAmountSection(),
                  const SizedBox(height: 20),
                  _buildCardForm(),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTotalAndSubmit(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card,
              color: AppColors.textOnPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Up Wallet',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  'Add funds securely to your account',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final lastFour = cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '••••';
    final name = _nameController.text.trim().isEmpty ? 'YOUR NAME' : _nameController.text.trim().toUpperCase();
    final expiry = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              Text(
                'VISA',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textOnPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Text(
            '•••• •••• •••• $lastFour',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textOnPrimary,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Holder',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expires',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    expiry,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amount',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _quickAmounts.map((amount) {
            final isSelected = !_useCustomAmount && _selectedAmount == amount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _handleAmountSelect(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '$_currencySymbol$amount',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _handleCustomAmountChange,
          decoration: InputDecoration(
            hintText: 'Custom amount',
            prefixText: '$_currencySymbol ',
            prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [_CardNumberFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _saveCard,
              onChanged: (value) => setState(() => _saveCard = value ?? false),
              activeColor: AppColors.primary,
            ),
            Text(
              'Save card for future payments',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalAndSubmit() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You're adding",
                style: AppTextStyles.caption,
              ),
              Text(
                _formatCurrency(_finalAmount),
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isLoading || _finalAmount < 1 ? null : _handleSubmit,
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.credit_card, size: 18),
            label: Text(_isLoading ? 'Processing...' : 'Top Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    var formatted = '';
    for (var i = 0; i < digits.length && i < 16; i++) {
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
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) formatted += '/';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
