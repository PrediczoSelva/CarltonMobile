import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class PayPalPaymentScreen extends StatefulWidget {
  const PayPalPaymentScreen({super.key});

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  String? _orderId;
  bool _hasHandledReturn = false;

  @override
  void initState() {
    super.initState();
    _createOrderAndRedirect();
  }

  Future<void> _createOrderAndRedirect() async {
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

      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post<dynamic>(
        '/payment/paypal/create-order',
        data: {
          'flightId': flight.id,
          'amount': amount,
          'currency': session.currency ?? 'GBP',
          'summary': 'Carlton flight booking (flight ${flight.flightCode})',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final orderId = data['orderId'] as String?;
      String? approvalUrl = data['approvalUrl'] as String?;

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Unable to create PayPal order. Please try again.');
      }

      // If backend doesn't return approvalUrl, construct it for sandbox
      if (approvalUrl == null || approvalUrl.isEmpty) {
        // Use PayPal sandbox checkoutnow URL with deep link return/cancel
        final returnUrl = Uri.encodeComponent('carlton://paypal/success?orderId=$orderId');
        final cancelUrl = Uri.encodeComponent('carlton://paypal/cancel');
        approvalUrl = 'https://www.sandbox.paypal.com/checkoutnow?token=$orderId&returnUrl=$returnUrl&cancelUrl=$cancelUrl';
      }

      _orderId = orderId;
      session.paypalOrderId = orderId;

      if (!mounted) return;

      // Launch PayPal in external browser
      await _launchPayPal(approvalUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchPayPal(String approvalUrl) async {
    final uri = Uri.parse(approvalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        setState(() {
          _error = 'Could not launch PayPal. Please check your browser settings.';
          _isLoading = false;
        });
      }
    }
    // The app will be resumed via deep link when PayPal completes
    // We don't set _isLoading = false here because we wait for the deep link
  }

  void _checkForPayPalReturn() {
    if (_hasHandledReturn) return;
    
    final uri = GoRouterState.of(context).uri;
    if (uri.scheme == 'carlton' && uri.host == 'paypal') {
      final params = uri.queryParameters;
      final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      _hasHandledReturn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayPalReturn(status, params);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForPayPalReturn();
  }

  Future<void> _handlePayPalReturn(String status, Map<String, String> params) async {
    final orderId = params['orderId'] ?? _orderId ?? '';
    final captureId = params['captureId'] ?? '';
    final message = params['message'] ?? '';

    if (status == 'success' && orderId.isNotEmpty) {
      try {
        final apiClient = getIt<ApiClient>();
        await apiClient.post<dynamic>(
          '/payment/paypal/capture-order',
          data: {
            'orderId': orderId,
          },
        );

        final session = getIt<BookingSession>();
        session.paypalCaptureId = captureId.isNotEmpty ? captureId : orderId;

        final paymentMetadata = {
          'paymentMethod': 'paypal',
          'paymentStatus': 'succeeded',
          'paypalOrderId': orderId,
          'paypalCaptureId': captureId.isNotEmpty ? captureId : orderId,
          'paidAtUtc': DateTime.now().toUtc().toIso8601String(),
          'contactPhone': session.contactPhone ?? '',
          'contactCountry': session.contactCountry ?? '',
          'guestCheckout': false,
          'contactEmail': session.contactEmail ?? '',
        };

        session.paymentMetadataJson = jsonEncode(paymentMetadata);
        session.paymentMethod = 'paypal';

        if (mounted) {
          context.push('/booking/payment/process');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
            _isLoading = false;
          });
        }
      }
    } else if (status == 'error') {
      if (mounted) {
        setState(() {
          _error = message.isNotEmpty ? message : 'PayPal payment failed.';
          _isLoading = false;
        });
      }
    } else if (status == 'cancel') {
      if (mounted) {
        setState(() {
          _error = 'PayPal payment was cancelled.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;
    final currency = session.currency ?? 'GBP';

    return Scaffold(
      appBar: AppBar(title: const Text('Pay with PayPal')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Redirecting to PayPal...'),
                    ],
                  ),
                ),
              )
            : _error != null
                ? _buildErrorView(price, currency)
                : _buildWaitingView(price, currency),
      ),
    );
  }

  Widget _buildWaitingView(double price, String currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '£${price.toStringAsFixed(2)}',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Waiting for PayPal payment...',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the payment in your browser, then return to the app.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Check Payment Status',
              onPressed: _createOrderAndRedirect,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to payment method'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(double price, String currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '£${price.toStringAsFixed(2)}',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Retry',
              onPressed: _createOrderAndRedirect,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to payment method'),
            ),
          ],
        ),
      ),
    );
  }
}