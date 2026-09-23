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
  String? _orderId;

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

      _orderId = orderId;
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

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PayPalBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePayPalMessage(message.message);
        },
      )
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
          onPageFinished: (String url) {
            // Inject JavaScript to handle postMessage issues
            _injectPostMessageFix();
          },
        ),
      )
      ..loadHtmlString(_generatePayPalHtml(orderId, currency));

    if (mounted) {
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    }
  }

  void _injectPostMessageFix() {
    // Fix for PayPal SDK postMessage issue in WebView
    // This overrides the problematic postMessage calls
    const fixScript = '''
      (function() {
        // Store original postMessage
        const originalPostMessage = window.postMessage;
        
        // Override postMessage to handle about:// origin
        window.postMessage = function(message, targetOrigin, transfer) {
          // If targetOrigin is about:// or empty, use * instead
          if (!targetOrigin || targetOrigin === 'about://' || targetOrigin === 'about:blank') {
            targetOrigin = '*';
          }
          return originalPostMessage.call(this, message, targetOrigin, transfer);
        };
        
        // Also fix for PayPal's internal postRobot library
        if (window.bo && window.bo.postrobot_post_message) {
          const originalPostRobot = window.bo.postrobot_post_message;
          window.bo.postrobot_post_message = function(target, message, targetOrigin) {
            if (!targetOrigin || targetOrigin === 'about://' || targetOrigin === 'about:blank') {
              targetOrigin = '*';
            }
            return originalPostRobot.call(this, target, message, targetOrigin);
          };
        }
        
        // Notify Flutter that fix is applied
        if (window.PayPalBridge) {
          window.PayPalBridge.postMessage('postMessageFixApplied');
        }
      })();
    ''';
    _controller?.runJavaScript(fixScript);
  }

  Future<void> _handlePayPalMessage(String message) async {
    // Handle messages from PayPal SDK via JavaScript channel
    // This can be used for additional communication if needed
    debugPrint('PayPal message: $message');
  }

  Future<void> _handlePayPalResult(
      String status, Map<String, String> params) async {
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

  String _generatePayPalHtml(String orderId, String currency) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <meta http-equiv="Content-Security-Policy" content="default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; script-src * 'unsafe-inline' 'unsafe-eval'; style-src * 'unsafe-inline'; frame-src *;">
  <script src="https://www.paypal.com/sdk/js?client-id=sb&currency=${Uri.encodeComponent(currency)}&enable-funding=venmo&components=buttons&intent=capture&disable-funding=card,venmo"></script>
  <style>
    body { margin: 0; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #fff; }
    #paypal-button-container { max-width: 400px; margin: 0 auto; }
    .loading { text-align: center; padding: 20px; color: #666; }
  </style>
</head>
<body>
  <div id="paypal-button-container">
    <div class="loading">Loading PayPal...</div>
  </div>
  <script>
    // Wait for PayPal SDK to load
    function initPayPal() {
      if (typeof paypal === 'undefined' || !paypal.Buttons) {
        setTimeout(initPayPal, 100);
        return;
      }
      
      paypal.Buttons({
        style: { layout: 'vertical', color: 'gold', shape: 'rect', label: 'pay' },
        createOrder: function() {
          return Promise.resolve('$orderId');
        },
        onApprove: function(data, actions) {
          return actions.order.capture().then(function(details) {
            // Use JavaScript channel to communicate with Flutter
            if (window.PayPalBridge) {
              window.PayPalBridge.postMessage(JSON.stringify({
                type: 'success',
                orderId: data.orderID,
                captureId: details.id
              }));
            }
            // Also try navigation as fallback
            window.location.href = 'carlton://paypal/success?orderId=' + data.orderID + '&captureId=' + details.id;
          });
        },
        onError: function(err) {
          if (window.PayPalBridge) {
            window.PayPalBridge.postMessage(JSON.stringify({
              type: 'error',
              message: err.message || 'PayPal payment failed'
            }));
          }
          window.location.href = 'carlton://paypal/error?message=' + encodeURIComponent(err.message || 'PayPal payment failed');
        },
        onCancel: function() {
          if (window.PayPalBridge) {
            window.PayPalBridge.postMessage(JSON.stringify({ type: 'cancel' }));
          }
          window.location.href = 'carlton://paypal/cancel';
        }
      }).render('#paypal-button-container').catch(function(err) {
        console.error('PayPal render error:', err);
        if (window.PayPalBridge) {
          window.PayPalBridge.postMessage(JSON.stringify({
            type: 'error',
            message: 'Failed to render PayPal buttons: ' + err.message
          }));
        }
      });
    }
    
    initPayPal();
  </script>
</body>
</html>
''';
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
                              '£${price.toStringAsFixed(2)}',
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
              onPressed: _createOrder,
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