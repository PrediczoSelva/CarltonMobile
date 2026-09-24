import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
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
      title: 'Pay by Card',
      icon: Icons.credit_card,
    ),
    _PaymentMethod(
      id: 'paypal',
      title: 'PayPal',
      icon: Icons.account_balance_wallet,
    ),
    _PaymentMethod(
      id: 'super_pay',
      title: 'Super Pay',
      icon: Icons.flash_on,
    ),
    _PaymentMethod(
      id: 'barclays',
      title: 'Barclays Card',
      icon: Icons.account_balance,
    ),
    _PaymentMethod(
      id: 'crypto',
      title: 'Crypto Payment',
      icon: Icons.currency_bitcoin,
    ),
    _PaymentMethod(
      id: 'wallet',
      title: 'Carlton Wallet',
      icon: Icons.wallet,
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
      case 'super_pay':
        context.push(AppRoutes.superPayPayment);
        break;
      case 'barclays':
        context.push(AppRoutes.barclaysPayment);
        break;
      case 'crypto':
        context.push('/booking/payment/crypto');
        break;
      case 'wallet':
        context.push('/booking/payment/wallet');
        break;
      default:
        context.push('/booking/payment/process');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;

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
                  '£${price.toStringAsFixed(0)}',
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
