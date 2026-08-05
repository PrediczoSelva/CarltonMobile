import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../booking/presentation/bloc/booking_event.dart';
import '../../../booking/presentation/bloc/booking_state.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _createBooking();
  }

  void _createBooking() {
    final session = getIt<BookingSession>();

    if (session.pnr != null) {
      setState(() => _showSuccess = true);
      return;
    }

    context.read<BookingBloc>().add(
          CreateBookingRequested(
            flightId: session.selectedOutboundFlight?.id ?? 0,
            passengers: session.passengers,
            contactEmail: session.contactEmail ?? '',
            contactPhone: session.contactPhone ?? '',
            paymentMethod: session.paymentMethod ?? 'card',
            paymentMetadataJson: session.paymentMetadataJson,
          ),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop();
          }
          _handleState(state);
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            final isLoading = state is BookingLoading && !_showSuccess;
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
                            'Processing payment...',
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
                                'Payment failed',
                                style: AppTextStyles.h3,
                              ),
                              const SizedBox(height: 24),
                              Text(
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
