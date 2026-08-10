import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../booking/presentation/bloc/booking_state.dart';
import '../../../flight/domain/entities/flight.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _showSuccess = false;
  String? _error;

  bool _isLoadingState(BookingState state) {
    return state is BookingLoading || state is BookingInitial;
  }

  @override
  void initState() {
    super.initState();
    _createBooking();
  }

  Future<void> _createBooking() async {
    final session = getIt<BookingSession>();

    if (session.pnr != null) {
      setState(() => _showSuccess = true);
      return;
    }

    final flight = session.selectedOutboundFlight;
    if (flight == null) {
      _showError('No flight selected. Please search again.');
      return;
    }

    final source = flight.source.toLowerCase();
    final isProviderFlight = source.contains('atlas') ||
        source.contains('amadeus') ||
        source.contains('travelport') ||
        (flight.bookingKey != null && flight.bookingKey!.isNotEmpty);

    if (!isProviderFlight && flight.id <= 0) {
      _showError('Selected flight is no longer valid. Please search again.');
      return;
    }

    if (isProviderFlight &&
        (flight.bookingKey == null || flight.bookingKey!.isEmpty)) {
      _showError(
          'Selected flight is missing booking details. Please search again.');
      return;
    }

    setState(() => _error = null);

    try {
      final bookingRepository = getIt<BookingRepository>();
      final stripeIntentId = session.stripePaymentIntentId;
      final quotedTotal = session.totalPriceWithTaxes;

      if (quotedTotal < 0.50) {
        throw Exception(
            'The selected flight price is too low to process payment. Please select a different flight.');
      }

      Booking booking;

      if (source.contains('atlas') &&
          flight.bookingKey != null &&
          flight.bookingKey!.isNotEmpty) {
        booking = await _createAtlasBooking(
            bookingRepository, session, flight, stripeIntentId, quotedTotal);
      } else if (source.contains('amadeus') &&
          flight.bookingKey != null &&
          flight.bookingKey!.isNotEmpty) {
        booking = await _createAmadeusBooking(
            bookingRepository, session, flight, stripeIntentId, quotedTotal);
      } else if (source.contains('travelport') &&
          flight.bookingKey != null &&
          flight.bookingKey!.isNotEmpty) {
        booking = await _createTravelportBooking(
            bookingRepository, session, flight, stripeIntentId, quotedTotal);
      } else if (flight.id > 0) {
        booking = await _createCatalogBooking(session, flight, stripeIntentId);
      } else {
        throw Exception(
            'Unable to book this flight. Please select a different flight.');
      }

      if (stripeIntentId != null && booking.id > 0) {
        booking = await bookingRepository.finalizeBookingPayment(
          bookingId: booking.id,
          stripePaymentIntentId: stripeIntentId,
          paymentMetadataJson: session.paymentMetadataJson,
        );
      }

      session.pnr = booking.pnr;
      session.bookingReference = booking.pnr;
      session.bookingStatus = booking.status;
      session.totalPrice = booking.totalPrice;
      session.currency = booking.currency;

      if (mounted) {
        setState(() => _showSuccess = true);
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Booking> _createAtlasBooking(
    BookingRepository repo,
    BookingSession session,
    Flight flight,
    String? stripeIntentId,
    double quotedTotal,
  ) async {
    return repo.createAtlasBooking(
      routingIdentifier: flight.bookingKey!,
      passengers: session.passengers,
      contactName: session.contactEmail ?? '',
      contactEmail: session.contactEmail ?? '',
      contactPhone: session.contactPhone ?? '',
      bookingClass: 'Economy',
      quotedTotal: quotedTotal,
      flightSnapshotJson: jsonEncode(flight.toJson()),
      stripePaymentIntentId: stripeIntentId,
      isGuest: false,
    );
  }

  Future<Booking> _createAmadeusBooking(
    BookingRepository repo,
    BookingSession session,
    Flight flight,
    String? stripeIntentId,
    double quotedTotal,
  ) async {
    return repo.createAmadeusBooking(
      amadeusOfferToken: flight.bookingKey!,
      verifyId: '',
      stripePaymentIntentId: stripeIntentId ?? '',
      baseFareTotal: quotedTotal,
      passengers: session.passengers,
      contactEmail: session.contactEmail ?? '',
      contactPhone: session.contactPhone ?? '',
      bookingClass: 'Economy',
      quotedTotal: quotedTotal,
      flightSnapshotJson: jsonEncode(flight.toJson()),
      isGuest: false,
    );
  }

  Future<Booking> _createTravelportBooking(
    BookingRepository repo,
    BookingSession session,
    Flight flight,
    String? stripeIntentId,
    double quotedTotal,
  ) async {
    return repo.createTravelportBooking(
      fareKey: flight.bookingKey!,
      segmentKeys: flight.segmentKeys,
      passengers: session.passengers,
      contactEmail: session.contactEmail ?? '',
      contactPhone: session.contactPhone ?? '',
      bookingClass: 'Economy',
      quotedTotal: quotedTotal,
      providerBaseFare: quotedTotal,
      flightSnapshotJson: jsonEncode(flight.toJson()),
      stripePaymentIntentId: stripeIntentId,
      isGuest: false,
    );
  }

  Future<Booking> _createCatalogBooking(
    BookingSession session,
    Flight flight,
    String? stripeIntentId,
  ) async {
    return getIt<BookingRepository>().createBooking(
      flightId: flight.id,
      passengers: session.passengers,
      contactEmail: session.contactEmail ?? '',
      contactPhone: session.contactPhone ?? '',
      paymentMethod: session.paymentMethod ?? 'card',
      paymentMetadataJson: session.paymentMetadataJson,
    );
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _error = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pop();
      });
    }
  }

  void _handleState(BookingState state) {
    if (state is BookingSuccess) {
      final session = getIt<BookingSession>();
      session.pnr = state.booking.pnr;
      session.bookingReference = state.booking.pnr;
      session.bookingStatus = state.booking.status;
      session.totalPrice = state.booking.totalPrice;
      session.currency = state.booking.currency;

      setState(() => _showSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            _showError(state.message);
          }
          _handleState(state);
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            final isLoading =
                _isLoadingState(state) && !_showSuccess && _error == null;
            final session = getIt<BookingSession>();
            final currency = session.currency ?? 'GBP';
            final price = session.totalPriceWithTaxes;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Processing booking...',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      )
                    : _showSuccess
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 72,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Payment successful',
                                style: AppTextStyles.h3,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$currency ${price.toStringAsFixed(0)} paid successfully',
                                style: AppTextStyles.bodyMedium,
                              ),
                              if (session.pnr != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'PNR: ${session.pnr}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'View confirmation',
                                onPressed: () =>
                                    context.push('/booking/confirmation'),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Booking failed',
                                style: AppTextStyles.h3,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _error ??
                                    'Please try again or select a different payment method.',
                                style: AppTextStyles.bodyMedium,
                                textAlign: TextAlign.center,
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
          },
        ),
      ),
    );
  }
}
