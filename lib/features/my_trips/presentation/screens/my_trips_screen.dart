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
      appBar: AppBar(
        title: const Text('My Bookings'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
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
    final confirmedCount = bookings
        .where((booking) => booking.status.toLowerCase() == 'confirmed')
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.03),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.textOnPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travel Portfolio',
                          style: AppTextStyles.bodySmall.copyWith(
                            letterSpacing: 0.35,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$confirmedCount confirmed of ${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final isDownloading = _downloadingIds.contains(booking.id);
                final isSelected = _selectedBookingId == booking.id;
                final isHovered = _hoveredBookingId == booking.id;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) =>
                      setState(() => _hoveredBookingId = booking.id),
                  onExit: (_) => setState(() => _hoveredBookingId = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.background, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentDark
                            : (isHovered
                                ? AppColors.primary.withOpacity(0.35)
                                : AppColors.border),
                        width: isSelected ? 1.7 : 1.15,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.06),
                          blurRadius: isSelected ? 20 : 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedBookingId = booking.id),
                        borderRadius: BorderRadius.circular(24),
                        splashColor: AppColors.accent.withOpacity(0.14),
                        highlightColor: AppColors.primary.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.flight_rounded,
                                      size: 20,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.flight.airline.isNotEmpty
                                              ? booking.flight.airline
                                              : 'Flight booking',
                                          style: AppTextStyles.h4.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
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
                                  _buildStatusChip(booking.status),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.flight.origin,
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            DateFormat('dd MMM').format(
                                                booking.flight.departureTime),
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('HH:mm').format(
                                                booking.flight.departureTime),
                                            style: AppTextStyles.h4.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Column(
                                        children: [
                                          Text(
                                            booking.flight.duration.isNotEmpty
                                                ? booking.flight.duration
                                                : 'Flight time',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 1,
                                                color: AppColors.border,
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 7),
                                                child: Icon(
                                                  Icons.flight_takeoff_rounded,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              Container(
                                                width: 20,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            booking.flight.destination,
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            DateFormat('dd MMM').format(
                                                booking.flight.arrivalTime),
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('HH:mm').format(
                                                booking.flight.arrivalTime),
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
                              const SizedBox(height: 14),
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
                                          icon: Icons
                                              .confirmation_number_outlined,
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
                              const SizedBox(height: 14),
                              const Divider(
                                  color: AppColors.divider, height: 1),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total trip',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.06),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppColors.primary
                                              .withOpacity(0.14),
                                        ),
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
                                        : const Icon(Icons.download_rounded,
                                            size: 18),
                                    label: Text(
                                      isDownloading
                                          ? 'Downloading...'
                                          : 'E-ticket',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isConfirmed = status.toLowerCase() == 'confirmed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isConfirmed
            ? AppColors.success.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isConfirmed
              ? AppColors.success.withOpacity(0.32)
              : AppColors.warning.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfirmed ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: isConfirmed ? AppColors.success : AppColors.textOnAccent,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppTextStyles.badge.copyWith(
              color: isConfirmed ? AppColors.success : AppColors.textOnAccent,
            ),
          ),
        ],
      ),
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
        color: AppColors.surface,
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
