import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

class WalletPaymentScreen extends StatefulWidget {
  const WalletPaymentScreen({super.key});

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  double? _balance;
  String? _currency;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final repository = getIt<WalletRepository>();
      final summary = await repository.getWalletSummary();
      setState(() {
        _balance = summary.balance;
        _currency = summary.currencyCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _payWithWallet() async {
    final session = getIt<BookingSession>();
    final amount = session.totalPriceWithTaxes;

    if (_balance == null || _balance! < amount) {
      setState(() {
        _error =
            'Insufficient wallet balance. Current balance: $_currency ${_balance?.toStringAsFixed(2) ?? '0.00'}';
      });
      return;
    }

    setState(() => _error = null);

    try {
      final authRepository = getIt<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      final userId = user.id;

      if (userId <= 0) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final paymentMetadata = {
        'paymentMethod': 'wallet',
        'paymentStatus': 'succeeded',
        'payWithWallet': true,
        'paidAtUtc': DateTime.now().toUtc().toIso8601String(),
        'contactPhone': session.contactPhone ?? '',
        'contactCountry': session.contactCountry ?? '',
        'guestCheckout': false,
        'contactEmail': session.contactEmail ?? '',
      };

      session.paymentMetadataJson = jsonEncode(paymentMetadata);
      session.paymentMethod = 'wallet';
      session.walletPayUserId = userId;

      if (mounted) {
        context.push('/booking/payment/process');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;
    final currency = session.currency ?? 'GBP';

    return Scaffold(
      appBar: AppBar(title: const Text('Pay with Wallet')),
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
                      '$currency ${price.toStringAsFixed(2)}',
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
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet,
                                  color: AppColors.primary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wallet balance',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currency ?? 'USD'} ${_balance?.toStringAsFixed(2) ?? '0.00'}',
                                      style: AppTextStyles.h4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Pay with Wallet',
                          onPressed: _payWithWallet,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
