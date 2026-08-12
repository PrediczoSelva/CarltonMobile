import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/data/models/e_ticket_models.dart';
import '../../../booking/presentation/utils/e_ticket_pdf_generator.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late final BookingSession _session;
  final BookingRepository _bookingRepository = getIt<BookingRepository>();

  Timer? _statusTimer;
  ETicketData? _ticketData;
  bool _isCheckingStatus = false;
  bool _isDownloading = false;
  String? _ticketError;

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _checkETicketStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkETicketStatus();
    });
  }

  Future<void> _checkETicketStatus() async {
    final bookingId = _session.bookingId;
    if (bookingId == null || bookingId <= 0) return;

    if (!mounted || _isCheckingStatus) return;

    setState(() => _isCheckingStatus = true);

    try {
      final data = await _bookingRepository.getETicketStatus(bookingId);
      if (!mounted) return;
      setState(() {
        _ticketData = data;
        _ticketError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ticketError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _downloadETicket() async {
    final bookingId = _session.bookingId;
    if (bookingId == null || bookingId <= 0) return;

    if (!mounted || _isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final data = await _bookingRepository.downloadETicket(bookingId);
      if (!mounted) return;

      final file = await ETicketPdfGenerator.generateETicket(data);
      if (!mounted) return;

      await ETicketPdfGenerator.openFile(file);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download e-ticket: $message')),
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
    final isTicketIssued = _ticketData?.issued ?? false;
    final canDownload = isTicketIssued && _session.bookingId != null;

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
              'E-ticket',
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
          _buildTicketStatusCard(isTicketIssued),
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
          if (_ticketError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _ticketError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton.icon(
            onPressed: canDownload && !_isDownloading ? _downloadETicket : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canDownload ? AppColors.success : AppColors.disabled,
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
              canDownload ? 'Download e-ticket' : 'Waiting for ticket issuance...',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _statusTimer?.cancel();
              _session.reset();
              context.go('/home');
            },
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStatusCard(bool isIssued) {
    return Card(
      color: isIssued
          ? AppColors.success.withOpacity(0.08)
          : AppColors.warning.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isIssued ? Icons.check_circle : Icons.pending,
              color: isIssued ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIssued ? 'Ticket issued' : 'Waiting for ticket',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isIssued
                        ? 'Your e-ticket is ready to download.'
                        : 'We are waiting for the airline to issue your ticket. This usually takes a few minutes.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (_isCheckingStatus && !isIssued)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
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
