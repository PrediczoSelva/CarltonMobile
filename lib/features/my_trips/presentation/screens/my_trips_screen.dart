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
  int? _selectedBookingId;
  int? _hoveredBookingId;

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
      appBar: AppBar(title: const Text('My Bookings')),
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
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isDownloading = _downloadingIds.contains(booking.id);
        final isSelected = _selectedBookingId == booking.id;
        final isHovered = _hoveredBookingId == booking.id;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredBookingId = booking.id),
          onExit: (_) => setState(() => _hoveredBookingId = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.surfaceVariant : AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : (isHovered ? AppColors.primaryLight : AppColors.border),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => setState(() => _selectedBookingId = booking.id),
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColors.accent.withOpacity(0.15),
                highlightColor: AppColors.primary.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.flight,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.flight.airline.isNotEmpty
                                      ? booking.flight.airline
                                      : 'Flight booking',
                                  style: AppTextStyles.h4,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.flight.flightCode.isNotEmpty
                                      ? booking.flight.flightCode
                                      : 'Trip reference',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: booking.status.toLowerCase() == 'confirmed'
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    booking.status.toLowerCase() == 'confirmed'
                                        ? AppColors.success.withOpacity(0.3)
                                        : AppColors.warning.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              booking.status,
                              style: AppTextStyles.badge.copyWith(
                                color:
                                    booking.status.toLowerCase() == 'confirmed'
                                        ? AppColors.success
                                        : AppColors.textOnAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.flight.origin,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd MMM')
                                        .format(booking.flight.departureTime),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(booking.flight.departureTime),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  Text(
                                    booking.flight.duration.isNotEmpty
                                        ? booking.flight.duration
                                        : 'Flight time',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(
                                          Icons.flight_takeoff_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Container(
                                        width: 22,
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    booking.flight.stopsText,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    booking.flight.destination,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd MMM')
                                        .format(booking.flight.arrivalTime),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(booking.flight.arrivalTime),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _TripMetaChip(
                                  icon: Icons.people_alt_outlined,
                                  label:
                                      '${booking.passengers.length} traveller${booking.passengers.length == 1 ? '' : 's'}',
                                ),
                                _TripMetaChip(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'PNR ${booking.pnr}',
                                ),
                              ],
                            ),
                          ),
                          if (booking.flight.aircraft.isNotEmpty)
                            Text(
                              booking.flight.aircraft,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total trip',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.currency} ${booking.totalPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.price,
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: isDownloading
                                ? null
                                : () => _downloadConfirmation(booking),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: isDownloading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(
                              isDownloading ? 'Downloading...' : 'E-ticket',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

      final bytes =
          response.data as List<int>? ?? (response.data as Uint8List?);
      if (bytes == null || bytes.isEmpty) {
        throw Exception(
            'Booking confirmation is empty. Please try again later.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeRef =
          (booking.pnr.isNotEmpty ? booking.pnr : booking.id.toString())
              .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}/booking_confirmation_$safeRef.html');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      if (status == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Booking confirmation is not available yet. It may take a few minutes after payment.')),
        );
      } else if (status == 401 || status == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please log in again to download your booking confirmation.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Unable to download confirmation right now (status $status). Please try again later.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to download booking confirmation: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(booking.id));
      }
    }
  }
}

class _TripMetaChip extends StatelessWidget {
  const _TripMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
