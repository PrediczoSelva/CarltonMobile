import 'dart:async';
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

enum PayPalPaymentState {
  loading,
  redirecting,
  waiting,
  success,
  failed,
  cancelled,
  error,
}

class PayPalPaymentScreen extends StatefulWidget {
  const PayPalPaymentScreen({super.key});

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  PayPalPaymentState _state = PayPalPaymentState.loading;
  String? _error;
  String? _orderId;
  String? _captureId;
  String? _payerEmail;
  String? _failureReason;
  bool _hasHandledReturn = false;
  Timer? _statusCheckTimer;
  int _waitTime = 0;

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

      setState(() => _state = PayPalPaymentState.redirecting);

      // Launch PayPal in external browser
      await _launchPayPal(approvalUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _state = PayPalPaymentState.error;
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
          _state = PayPalPaymentState.error;
        });
      }
      return;
    }
    // Start status check timer after launching PayPal
    _startStatusCheckTimer();
    if (mounted && _state == PayPalPaymentState.redirecting) {
      setState(() {
        _state = PayPalPaymentState.waiting;
        _waitTime = 0;
      });
    }
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _waitTime += 3;
      });
      // Check payment status every 15 seconds via backend
      if (_waitTime % 15 == 0 && _orderId != null) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderId == null) return;
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post<dynamic>(
        '/payment/paypal/capture-order',
        data: {'orderId': _orderId},
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      );
      if (mounted && response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        final captureId = data['captureId'] as String? ?? '';
        final payerEmail = data['payerEmail'] as String? ?? '';
        
        if (status.toUpperCase() == 'COMPLETED' || captureId.isNotEmpty) {
          _statusCheckTimer?.cancel();
          _handlePayPalReturn('success', {
            'orderId': _orderId!,
            'captureId': captureId,
            'payerEmail': payerEmail,
          });
        }
      }
    } catch (e) {
      // Ignore errors during periodic check
      debugPrint('PayPal status check failed: $e');
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
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
    final payerEmail = params['payerEmail'] ?? '';

    if (status == 'success' && orderId.isNotEmpty) {
      try {
        final apiClient = getIt<ApiClient>();
        await apiClient.post<dynamic>(
          '/payment/paypal/capture-order',
          data: {
            'orderId': orderId,
          },
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        );

        final session = getIt<BookingSession>();
        session.paypalCaptureId = captureId.isNotEmpty ? captureId : orderId;
        _captureId = captureId.isNotEmpty ? captureId : orderId;
        _payerEmail = payerEmail.isNotEmpty ? payerEmail : null;

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
          setState(() => _state = PayPalPaymentState.success);
          // Auto-navigate to payment processing after 2 seconds
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.push('/booking/payment/process');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _failureReason = e.toString().replaceFirst('Exception: ', '');
            _state = PayPalPaymentState.failed;
          });
        }
      }
    } else if (status == 'error') {
      if (mounted) {
        setState(() {
          _failureReason = message.isNotEmpty ? message : 'PayPal payment failed.';
          _state = PayPalPaymentState.failed;
        });
      }
    } else if (status == 'cancel') {
      if (mounted) {
        setState(() {
          _failureReason = 'PayPal payment was cancelled by the user.';
          _state = PayPalPaymentState.cancelled;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _failureReason = null;
      _state = PayPalPaymentState.loading;
      _hasHandledReturn = false;
    });
    _createOrderAndRedirect();
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;
    final currency = session.currency ?? 'GBP';

    return Scaffold(
      appBar: AppBar(title: const Text('Pay with PayPal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(price, currency),
        ),
      ),
    );
  }

  Widget _buildBody(double price, String currency) {
    switch (_state) {
      case PayPalPaymentState.loading:
        return _buildLoadingView();
      case PayPalPaymentState.redirecting:
        return _buildRedirectingView();
      case PayPalPaymentState.waiting:
        return _buildWaitingView(price);
      case PayPalPaymentState.success:
        return _buildSuccessView(price);
      case PayPalPaymentState.failed:
        return _buildFailureView(price, _failureReason ?? 'Payment failed');
      case PayPalPaymentState.cancelled:
        return _buildCancelledView(price);
      case PayPalPaymentState.error:
        return _buildErrorView(price, _error ?? 'An error occurred');
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Creating PayPal order...'),
        ],
      ),
    );
  }

  Widget _buildRedirectingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Redirecting to PayPal...'),
        ],
      ),
    );
  }

  Widget _buildWaitingView(double price) {
    return Center(
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
          if (_waitTime > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Waiting for ${_waitTime}s...',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Check Payment Status Now',
            onPressed: _checkPaymentStatus,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to payment method'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(double price) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: AppTextStyles.h3.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your PayPal payment has been processed successfully.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Amount Paid', '£${price.toStringAsFixed(2)}'),
          if (_orderId != null) _buildDetailRow('Order ID', _orderId!),
          if (_captureId != null) _buildDetailRow('Capture ID', _captureId!),
          if (_payerEmail != null) _buildDetailRow('Payer Email', _payerEmail!),
          _buildDetailRow('Payment Method', 'PayPal'),
          _buildDetailRow('Status', 'Completed', valueColor: AppColors.success),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Continue to Booking',
            onPressed: () => context.push('/booking/payment/process'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to payment method'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureView(double price, String reason) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error, color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Failed',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your PayPal payment could not be completed.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason:',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Amount', '£${price.toStringAsFixed(2)}'),
          if (_orderId != null) _buildDetailRow('Order ID', _orderId!),
          _buildDetailRow('Payment Method', 'PayPal'),
          _buildDetailRow('Status', 'Failed', valueColor: AppColors.error),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Retry Payment',
            onPressed: _retry,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to payment method'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView(double price) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, color: AppColors.warning, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Cancelled',
            style: AppTextStyles.h3.copyWith(color: AppColors.warning),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You cancelled the PayPal payment.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Amount', '£${price.toStringAsFixed(2)}'),
          if (_orderId != null) _buildDetailRow('Order ID', _orderId!),
          _buildDetailRow('Payment Method', 'PayPal'),
          _buildDetailRow('Status', 'Cancelled', valueColor: AppColors.warning),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Try Again',
            onPressed: _retry,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to payment method'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(double price, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Error',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred while processing your payment.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Retry',
            onPressed: _retry,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to payment method'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}