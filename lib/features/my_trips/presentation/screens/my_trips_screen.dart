import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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
  final Set<int> _downloadingIds = {};

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
        final isDownloading = _downloadingIds.contains(booking.id);
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.flight.origin,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy · HH:mm').format(booking.flight.departureTime),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
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
                              '${booking.flight.stopsText}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            booking.flight.destination,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy · HH:mm').format(booking.flight.arrivalTime),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (booking.passengers.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.passengers.map((p) => p.fullName).join(', '),
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
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
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: isDownloading
                          ? null
                          : () => _downloadConfirmation(booking),
                      icon: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(
                        isDownloading ? 'Downloading...' : 'Confirmation',
                        style: AppTextStyles.bodySmall,
                      ),
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

  Future<void> _downloadConfirmation(Booking booking) async {
    if (_downloadingIds.contains(booking.id)) return;

    setState(() => _downloadingIds.add(booking.id));

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.dio.get<dynamic>(
        AppConstants.eTicketDownload.replaceAll('{id}', booking.id.toString()),
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as List<int>? ?? (response.data as Uint8List?);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Booking confirmation is empty. Please try again later.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeRef = (booking.pnr.isNotEmpty ? booking.pnr : booking.id.toString())
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
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
        setState(() => _downloadingIds.remove(booking.id));
      }
    }
  }
}
