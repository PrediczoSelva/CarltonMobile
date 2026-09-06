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

class PayPalPaymentScreen extends StatefulWidget {
  const PayPalPaymentScreen({super.key});

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  Future<void> _createOrder() async {
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

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Unable to create PayPal order. Please try again.');
      }

      session.paypalOrderId = orderId;

      if (mounted) {
        _loadPayPalCheckout(orderId);
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

  Future<void> _loadPayPalCheckout(String orderId) async {
    final session = getIt<BookingSession>();
    final currency = session.currency ?? 'GBP';

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.paypal.com/sdk/js?client-id=sb&currency=${Uri.encodeComponent(currency)}&enable-funding=venmo&components=buttons&intent=capture"></script>
</head>
<body>
  <div id="paypal-button-container"></div>
  <script>
    paypal.Buttons({
      style: { layout: 'vertical', color: 'gold', shape: 'rect', label: 'pay' },
      createOrder: function() {
        return Promise.resolve('$orderId');
      },
      onApprove: function(data, actions) {
        return actions.order.capture().then(function(details) {
          window.location.href = 'carlton://paypal/success?orderId=' + data.orderID + '&captureId=' + details.id;
        });
      },
      onError: function(err) {
        window.location.href = 'carlton://paypal/error?message=' + encodeURIComponent(err.message || 'PayPal payment failed');
      },
      onCancel: function() {
        window.location.href = 'carlton://paypal/cancel';
      }
    }).render('#paypal-button-container');
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
            if (uri.scheme == 'carlton' && uri.host == 'paypal') {
              final params = uri.queryParameters;
              final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
              _handlePayPalResult(status, params);
              return NavigationDecision.prevent;
            }
            if (uri.host == 'paypal.com' || uri.host == 'sandbox.paypal.com') {
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

  Future<void> _handlePayPalResult(
      String status, Map<String, String> params) async {
    final orderId = params['orderId'] ?? session.paypalOrderId ?? '';
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
          });
        }
      }
    } else if (status == 'error') {
      if (mounted) {
        setState(() {
          _error = message.isNotEmpty ? message : 'PayPal payment failed.';
        });
      }
    } else if (status == 'cancel') {
      if (mounted) {
        setState(() {
          _error = 'PayPal payment was cancelled.';
        });
      }
    }
  }

  BookingSession get session => getIt<BookingSession>();

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
