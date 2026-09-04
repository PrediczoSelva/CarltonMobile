import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  const PaymentMethodSelectionScreen({super.key});

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  String? _selectedMethod;

  static const _methods = [
    _PaymentMethod(
      id: 'card',
      title: 'Card payment',
      icon: Icons.credit_card,
    ),
    _PaymentMethod(
      id: 'paypal',
      title: 'PayPal',
      icon: Icons.account_balance_wallet,
    ),
    _PaymentMethod(
      id: 'wallet',
      title: 'Wallet',
      icon: Icons.wallet,
    ),
    _PaymentMethod(
      id: 'barclays',
      title: 'Barclays Pay',
      icon: Icons.account_balance,
    ),
  ];

  void _continue() {
    if (_selectedMethod == null) return;

    final session = getIt<BookingSession>();
    session.paymentMethod = _selectedMethod;

    switch (_selectedMethod) {
      case 'card':
        context.push('/booking/payment/card');
        break;
      case 'paypal':
        context.push('/booking/payment/paypal');
        break;
      case 'wallet':
        context.push('/booking/payment/wallet');
        break;
      case 'barclays':
        context.push('/booking/payment/barclays');
        break;
      default:
        context.push('/booking/payment/process');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;
    final currency = session.currency ?? 'GBP';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          ..._methods.map(
            (method) => RadioListTile<String>(
              value: method.id,
              groupValue: _selectedMethod,
              onChanged: (value) => setState(() => _selectedMethod = value),
              title: Row(
                children: [
                  Icon(method.icon, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(method.title, style: AppTextStyles.bodyLarge),
                ],
              ),
              secondary: _selectedMethod == method.id
                  ? Icon(Icons.check_circle, color: AppColors.accent)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continue',
            onPressed: _selectedMethod == null ? null : _continue,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod({required this.id, required this.title, required this.icon});

  final String id;
  final String title;
  final IconData icon;
}
