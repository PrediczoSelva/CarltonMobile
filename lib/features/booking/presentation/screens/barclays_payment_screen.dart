import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class BarclaysPaymentScreen extends StatefulWidget {
  const BarclaysPaymentScreen({super.key});

  @override
  State<BarclaysPaymentScreen> createState() => _BarclaysPaymentScreenState();
}

class _BarclaysPaymentScreenState extends State<BarclaysPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _createCaptureContext();
  }

  Future<void> _createCaptureContext() async {
    try {
      final session = getIt<BookingSession>();
      final amount = session.totalPriceWithTaxes;

      if (amount < 0.50) {
        throw Exception(
            'The selected flight price is too low to process payment. Please select a different flight.');
      }

      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post<dynamic>(
        '/api/smartpay/capture-context',
        data: {
          'amount': amount,
          'currency': session.currency ?? 'GBP',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final captureContext = data['captureContext'] as String?;

      if (captureContext == null || captureContext.isEmpty) {
        throw Exception('Unable to start Barclaycard payment session. Please try again.');
      }

      if (mounted) {
        _loadSmartpayWidget(captureContext);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSmartpayWidget(String captureContext) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://js.barclaycardsmartpay.com/checkout-sdk/latest/checkout.min.js"></script>
</head>
<body>
  <div id="container"></div>
  <script>
    (function() {
      try {
        const checkout = window.Smartpay(captureContext);
        checkout.mount('#container');
        checkout.on('paymentCompleted', function(event) {
          window.location.href = 'carlton://barclays/success?transientToken=' + encodeURIComponent(event.transientToken || '');
        });
        checkout.on('paymentFailed', function(event) {
          window.location.href = 'carlton://barclays/error?message=' + encodeURIComponent(event.message || 'Barclaycard payment failed');
        });
        checkout.on('paymentCancelled', function() {
          window.location.href = 'carlton://barclays/cancel';
        });
      } catch (e) {
        window.location.href = 'carlton://barclays/error?message=' + encodeURIComponent(e.message || 'Failed to load payment widget');
      }
    })();
  </script>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.scheme == 'carlton' && uri.host == 'barclays') {
              final params = uri.queryParameters;
              final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
              _handleBarclaysResult(status, params);
              return NavigationDecision.prevent;
            }
            if (uri.host.contains('barclaycard') || uri.host.contains('smartpay') || uri.host.contains('adyen')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _error = 'WebView error: ${error.description}';
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(html);

    if (mounted) {
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBarclaysResult(
      String status, Map<String, String> params) async {
    final transientToken = params['transientToken'] ?? '';
    final message = params['message'] ?? '';

    if (status == 'success' && transientToken.isNotEmpty) {
      try {
        final apiClient = getIt<ApiClient>();
        final session = getIt<BookingSession>();

        final authResponse = await apiClient.post<dynamic>(
          '/api/smartpay/authorize',
          data: {
            'transientToken': transientToken,
            'amount': session.totalPriceWithTaxes,
            'currency': session.currency ?? 'GBP',
            'reference': 'FLIGHT-${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        final authData = authResponse.data as Map<String, dynamic>?;
        final paymentId = authData?['paymentId'] as String? ?? transientToken;

        final confirmResponse = await apiClient.post<dynamic>(
          '/api/smartpay/confirm',
          data: {
            'transientToken': transientToken,
          },
        );

        final confirmData = confirmResponse.data as Map<String, dynamic>?;
        final cardLast4 = confirmData?['cardLast4'] as String? ?? '';

        final paymentMetadata = {
          'paymentMethod': 'barclaycard',
          'paymentStatus': 'succeeded',
          'barclaycardReference': paymentId,
          'barclaycardLast4': cardLast4,
          'paidAtUtc': DateTime.now().toUtc().toIso8601String(),
          'contactPhone': session.contactPhone ?? '',
          'contactCountry': session.contactCountry ?? '',
          'guestCheckout': false,
          'contactEmail': session.contactEmail ?? '',
        };

        session.paymentMetadataJson = jsonEncode(paymentMetadata);
        session.paymentMethod = 'barclays';
        session.barclaycardReference = paymentId;

        if (mounted) {
          context.push('/booking/payment/process');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } else if (status == 'error') {
      if (mounted) {
        setState(() {
          _error = message.isNotEmpty ? message : 'Barclaycard payment failed.';
        });
      }
    } else if (status == 'cancel') {
      if (mounted) {
        setState(() {
          _error = 'Barclaycard payment was cancelled.';
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
      appBar: AppBar(title: const Text('Pay with Barclays')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _error != null
                ? _buildErrorView(price, currency)
                : _controller != null
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '$currency ${price.toStringAsFixed(2)}',
                              style: AppTextStyles.h4,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: WebViewWidget(controller: _controller!),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
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
            const SizedBox(height: 24),
            Text(
              '$currency ${price.toStringAsFixed(2)}',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back to payment method',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
