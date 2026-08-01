import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../booking/presentation/bloc/booking_event.dart';
import '../../../booking/presentation/bloc/booking_state.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingBloc>().add(GetUserBookingsRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is BookingsListLoaded) {
            if (state.bookings.isEmpty) {
              return _buildEmpty();
            }
            return _buildList(state.bookings);
          }
          if (state is BookingError) {
            return _buildError(state.message);
          }
          return _buildEmpty();
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.airplane_ticket,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming trips',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookings will appear here once you make them',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                context.read<BookingBloc>().add(GetUserBookingsRequested());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Booking> bookings) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${booking.flight.airline} ${booking.flight.flightCode}',
                      style: AppTextStyles.h4,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: booking.status == 'Confirmed'
                            ? AppColors.success
                            : AppColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.flight.origin,
                          style: AppTextStyles.h3,
                        ),
                        Text(
                          DateFormat('MMM d').format(booking.flight.departureTime),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Text(
                              booking.flight.duration,
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              color: AppColors.border,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${booking.passengers.length} passenger(s)',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          booking.flight.destination,
                          style: AppTextStyles.h3,
                        ),
                        Text(
                          DateFormat('MMM d').format(booking.flight.arrivalTime),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${booking.currency} ${booking.totalPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.price,
                    ),
                    const Spacer(),
                    Text(
                      'PNR: ${booking.pnr}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
