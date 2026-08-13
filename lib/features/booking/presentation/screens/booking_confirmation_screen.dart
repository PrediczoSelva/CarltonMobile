import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking_session.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late final BookingSession _session;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
  }

  Future<void> _downloadBookingConfirmation() async {
    final bookingId = _session.bookingId;
    if (bookingId == null || bookingId <= 0) return;

    if (!mounted || _isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.dio.get<dynamic>(
        AppConstants.eTicketDownload.replaceAll('{id}', bookingId.toString()),
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;

      final bytes = response.data as List<int>? ?? (response.data as Uint8List?);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Booking confirmation is empty. Please try again later.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeRef = (_session.pnr ?? bookingId.toString()).replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}/booking_confirmation_$safeRef.html');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      if (status == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmation is not available yet. It may take a few minutes after payment.')),
        );
      } else if (status == 401 || status == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again to download your booking confirmation.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to download confirmation right now (status $status). Please try again later.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download booking confirmation: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, MMM d, yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    final flight = _session.selectedOutboundFlight;
    final currency = _session.currency ?? flight?.currency ?? 'GBP';
    final price = _session.totalPriceWithTaxes;
    final pnr = _session.pnr ?? '—';
    final passengers = _session.passengers;
    final hasBookingId = _session.bookingId != null && _session.bookingId! > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Icon(
              Icons.confirmation_number,
              color: AppColors.success,
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Booking Confirmation',
              style: AppTextStyles.h3,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              pnr,
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.info.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your payment is confirmed',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'E-ticket issuance may take up to 48 hours. You can download your booking confirmation now. If the e-ticket is not issued within 48 hours, please contact us.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmationSection(
            title: 'Flight',
            children: [
              if (flight != null) ...[
                _ConfirmationRow(
                  label: 'Flight',
                  value: '${flight.airline} ${flight.flightCode}',
                ),
                _ConfirmationRow(
                  label: 'Route',
                  value: '${flight.origin} → ${flight.destination}',
                ),
                _ConfirmationRow(
                  label: 'Departure',
                  value:
                      '${_formatDate(flight.departureTime)} ${_formatTime(flight.departureTime)}',
                ),
                _ConfirmationRow(
                  label: 'Arrival',
                  value:
                      '${_formatDate(flight.arrivalTime)} ${_formatTime(flight.arrivalTime)}',
                ),
                _ConfirmationRow(label: 'Aircraft', value: flight.aircraft),
                _ConfirmationRow(label: 'Duration', value: flight.duration),
                _ConfirmationRow(label: 'Stops', value: flight.stopsText),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _ConfirmationSection(
            title: 'Passengers',
            children: [
              for (var i = 0; i < passengers.length; i++)
                _ConfirmationRow(
                  label: i == 0 ? 'Lead passenger' : 'Passenger ${i + 1}',
                  value: passengers[i].fullName,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _ConfirmationSection(
            title: 'Contact',
            children: [
              _ConfirmationRow(
                label: 'Email',
                value: _session.contactEmail ?? '—',
              ),
              _ConfirmationRow(
                label: 'Phone',
                value: _session.contactPhone ?? '—',
              ),
              _ConfirmationRow(
                label: 'Country',
                value: _session.contactCountry ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ConfirmationSection(
            title: 'Payment',
            children: [
              _ConfirmationRow(
                label: 'Total paid',
                value: '$currency ${price.toStringAsFixed(0)}',
              ),
              _ConfirmationRow(
                label: 'Payment method',
                value: _session.paymentMethod ?? '—',
              ),
              _ConfirmationRow(
                label: 'Status',
                value: _session.bookingStatus ?? 'Confirmed',
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: hasBookingId && !_isDownloading ? _downloadBookingConfirmation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasBookingId ? AppColors.primary : AppColors.disabled,
            ),
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(
              'Download Booking Confirmation',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _session.reset();
              context.go('/home');
            },
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationSection extends StatelessWidget {
  const _ConfirmationSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
