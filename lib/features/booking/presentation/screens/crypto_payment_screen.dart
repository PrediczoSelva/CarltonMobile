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

class CryptoPaymentScreen extends StatefulWidget {
  const CryptoPaymentScreen({super.key});

  @override
  State<CryptoPaymentScreen> createState() => _CryptoPaymentScreenState();
}

class _CryptoPaymentScreenState extends State<CryptoPaymentScreen> {
  bool _isLoading = true;
  bool _isChecking = false;
  String? _error;
  int? _bookingId;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  Future<void> _startPayment() async {
    try {
      final session = getIt<BookingSession>();
      final flight = session.selectedOutboundFlight;
      if (flight == null) {
        throw Exception('No flight selected. Please go back and search again.');
      }

      final amount = session.totalPriceWithTaxes;
      if (amount <= 0) {
        throw Exception('The selected flight has an invalid price.');
      }

      final apiClient = getIt<ApiClient>();
      final draftResponse = await apiClient.post<dynamic>(
        '/bookings/draft',
        data: {
          'draftSessionId':
              'mobile-crypto-${DateTime.now().microsecondsSinceEpoch}',
          'flightId': flight.id,
          'seatsBooked':
              session.passengers.isEmpty ? 1 : session.passengers.length,
          'bookingClass': 'Economy',
          'passengerNames':
              session.passengers.map((p) => p.fullName).join(', '),
          'passengerDetailsJson': jsonEncode(
            session.passengers.map((passenger) => passenger.toJson()).toList(),
          ),
          'flightSnapshotJson': jsonEncode(flight.toJson()),
          'contactEmail': session.contactEmail,
          'contactPhone': session.contactPhone,
          'contactPhoneCountry': session.contactCountry,
          'quotedTotal': amount,
          'dataSource': flight.source,
        },
      );

      final draft = _asMap(draftResponse.data);
      final bookingId = _parseInt(draft['id'] ?? draft['bookingId']);
      if (bookingId == null || bookingId <= 0) {
        throw Exception('Unable to create the booking payment session.');
      }

      final successUrl = 'carlton://crypto/success?bookingId=$bookingId';
      final orderResponse = await apiClient.post<dynamic>(
        '/payment/coingate/create-order',
        data: {
          'bookingId': bookingId,
          'flightId': flight.id,
          'amount': amount,
          'currency': session.currency ?? 'GBP',
          'summary': 'Carlton flight booking (flight ${flight.flightCode})',
          'successUrl': successUrl,
        },
      );

      final order = _asMap(orderResponse.data);
      final paymentUrl = order['paymentUrl'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Unable to start crypto payment. Please try again.');
      }

      _bookingId = bookingId;
      _orderId = order['orderId']?.toString();
      if (mounted) setState(() => _isLoading = false);

      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        setState(() => _error = 'Could not open the crypto payment page.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    final bookingId = _bookingId;
    if (bookingId == null || _isChecking) return;

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final response = await getIt<ApiClient>().get<dynamic>(
        '/payment/coingate/verify/$bookingId',
      );
      final data = _asMap(response.data);
      final status = (data['status'] as String? ?? 'Pending').toLowerCase();

      if (status == 'paid') {
        final session = getIt<BookingSession>();
        final booking = _asMap(data['booking']);
        session.bookingId =
            _parseInt(booking['id'] ?? booking['bookingId']) ?? bookingId;
        session.pnr =
            booking['pnr'] as String? ?? booking['bookingReference'] as String?;
        session.bookingReference = session.pnr;
        session.bookingStatus = booking['status'] as String? ?? 'Confirmed';
        session.paymentMethod = 'crypto';
        session.paymentMetadataJson = jsonEncode({
          'paymentMethod': 'crypto',
          'paymentProvider': 'coingate',
          'paymentStatus': 'succeeded',
          'coingateOrderId': data['paymentReference'] ?? _orderId,
          'paidAtUtc': DateTime.now().toUtc().toIso8601String(),
        });
        if (mounted) context.push('/booking/confirmation');
      } else if (mounted) {
        setState(() {
          _error = status == 'failed'
              ? 'Crypto payment failed or expired.'
              : 'Payment is still pending. Complete it in the payment page, then check again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final price = session.totalPriceWithTaxes;

    return Scaffold(
      appBar: AppBar(title: const Text('Crypto payment')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
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
                          Text('Amount to pay',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textOnPrimary)),
                          const SizedBox(height: 8),
                          Text('£${price.toStringAsFixed(2)}',
                              style: AppTextStyles.h2
                                  .copyWith(color: AppColors.textOnPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.currency_bitcoin,
                        size: 56, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Pay securely with crypto',
                      style: AppTextStyles.h4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be redirected to CoinGate to choose your cryptocurrency and complete payment.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(
                      label: _isChecking
                          ? 'Checking payment...'
                          : 'Check payment status',
                      onPressed: _isChecking ? null : _checkPaymentStatus,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to payment method'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
