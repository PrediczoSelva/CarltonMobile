import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
      id: 'superpay',
      title: 'Super Pay',
      icon: Icons.payments,
    ),
    _PaymentMethod(
      id: 'barclays',
      title: 'Barclays Pay',
      icon: Icons.account_balance,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          ElevatedButton(
            onPressed: _selectedMethod == null
                ? null
                : () {
                    if (_selectedMethod == 'card') {
                      context.push('/booking/payment/card');
                    } else {
                      context.push('/booking/payment/process');
                    }
                  },
            child: const Text('Continue'),
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
