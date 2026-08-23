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
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../booking/presentation/bloc/booking_event.dart';
import '../../../booking/presentation/bloc/booking_state.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  final Set<int> _downloadingIds = {};
  final Set<int> _cancellingIds = {};
  int? _selectedBookingId;
  int? _hoveredBookingId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingBloc>().add(GetUserBookingsRequested());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            return _buildTabbedView(state.bookings);
          }
          if (state is BookingCancelled) {
            context.read<BookingBloc>().add(GetUserBookingsRequested());
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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

  Widget _buildTabbedView(List<Booking> allBookings) {
    final now = DateTime.now();
    final upcoming = allBookings.where((b) {
      final isCancelled = b.status.toLowerCase().contains('cancel');
      final isPast = b.flight.departureTime.isBefore(now);
      return !isCancelled && !isPast;
    }).toList();
    final finished = allBookings.where((b) {
      final isCancelled = b.status.toLowerCase().contains('cancel');
      final isPast = b.flight.departureTime.isBefore(now);
      return !isCancelled && isPast;
    }).toList();
    final cancelled = allBookings.where((b) {
      return b.status.toLowerCase().contains('cancel');
    }).toList();

    return Column(
      children: [
        _buildPortfolioHeader(allBookings),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Finished'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(upcoming, showCancel: true),
              _buildBookingList(finished, showCancel: false),
              _buildBookingList(cancelled, showCancel: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioHeader(List<Booking> bookings) {
    final confirmedCount = bookings
        .where((booking) => booking.status.toLowerCase() == 'confirmed')
        .length;

    return Padding(
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
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {required bool showCancel}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.airplane_ticket_outlined,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No trips here yet',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookings will appear in this section when available',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
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
          onEnter: (_) => setState(() => _hoveredBookingId = booking.id),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Departure',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.flight.origin.isEmpty
                                        ? '—'
                                        : booking.flight.origin,
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Destination',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.flight.destination.isEmpty
                                        ? '—'
                                        : booking.flight.destination,
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
                          _TripMetaChip(
                            icon: Icons
                                .confirmation_number_outlined,
                            label: 'PNR ${booking.pnr}',
                          ),
                          const Spacer(),
                          if (booking.flight.aircraft.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                booking.flight.aircraft,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () =>
                                _viewBookingDetails(booking),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: AppColors.primary
                                  .withOpacity(0.06),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                side: BorderSide(
                                  color: AppColors.primary
                                      .withOpacity(0.14),
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: Text(
                              'View',
                              style: AppTextStyles.bodySmall
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showCancel) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _cancellingIds.contains(booking.id)
                                  ? null
                                  : () => _cancelBooking(booking),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                backgroundColor:
                                    AppColors.error.withOpacity(0.08),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: AppColors.error
                                        .withOpacity(0.2),
                                  ),
                                ),
                              ),
                              icon: _cancellingIds.contains(booking.id)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.error,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _cancellingIds.contains(booking.id)
                                    ? 'Cancelling...'
                                    : 'Cancel',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(
                          color: AppColors.divider, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Future<void> _viewBookingDetails(Booking booking) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailsSheet(booking: booking),
    );
  }

  Widget _buildStatusChip(String status) {
    final lower = status.toLowerCase();
    final isCancelled = lower.contains('cancel');
    final isConfirmed = lower == 'confirmed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCancelled
            ? AppColors.error.withOpacity(0.12)
            : isConfirmed
                ? AppColors.success.withOpacity(0.12)
                : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withOpacity(0.32)
              : isConfirmed
                  ? AppColors.success.withOpacity(0.32)
                  : AppColors.warning.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCancelled
                ? Icons.cancel_rounded
                : isConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
            size: 12,
            color: isCancelled
                ? AppColors.error
                : isConfirmed
                    ? AppColors.success
                    : AppColors.textOnAccent,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppTextStyles.badge.copyWith(
              color: isCancelled
                  ? AppColors.error
                  : isConfirmed
                      ? AppColors.success
                      : AppColors.textOnAccent,
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

  Future<void> _cancelBooking(Booking booking) async {
    final now = DateTime.now();
    final departure = booking.flight.departureTime;
    final hoursToDeparture = departure.difference(now).inHours;

    String refundPolicy;
    String refundAmount;
    if (booking.status.toLowerCase() == 'confirmed' && hoursToDeparture > 24) {
      refundPolicy = 'Full refund';
      refundAmount =
          '${booking.currency} ${booking.totalPrice.toStringAsFixed(2)}';
    } else if (booking.status.toLowerCase() == 'confirmed' &&
        hoursToDeparture > 0) {
      refundPolicy = 'Partial refund';
      final refundValue = booking.totalPrice * 0.8;
      refundAmount = '${booking.currency} ${refundValue.toStringAsFixed(2)}';
    } else {
      refundPolicy = 'Non-refundable';
      refundAmount = '0.00';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
        title: Text(
          'Cancel booking ${booking.pnr.isNotEmpty ? booking.pnr : booking.id.toString()}?',
          style: AppTextStyles.h4,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refund policy',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    refundPolicy,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated refund: $refundAmount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _cancellingIds.add(booking.id));

    try {
      final repo = context.read<BookingRepository>();
      await repo.cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refundPolicy == 'Non-refundable'
                ? 'Booking cancelled. No refund applies.'
                : 'Booking cancelled. Refund: $refundAmount',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.read<BookingBloc>().add(GetUserBookingsRequested());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cancellation failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingIds.remove(booking.id));
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

class _BookingDetailsSheet extends StatelessWidget {
  const _BookingDetailsSheet({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final flight = booking.flight;
    final lower = booking.status.toLowerCase();
    final isCancelled = lower.contains('cancel');
    final isConfirmed = lower == 'confirmed';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNR ${booking.pnr}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? AppColors.error.withOpacity(0.12)
                        : isConfirmed
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isCancelled
                          ? AppColors.error.withOpacity(0.32)
                          : isConfirmed
                              ? AppColors.success.withOpacity(0.32)
                              : AppColors.warning.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    booking.status,
                    style: AppTextStyles.badge.copyWith(
                      color: isCancelled
                          ? AppColors.error
                          : isConfirmed
                              ? AppColors.success
                              : AppColors.textOnAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Flight', value: '${flight.airline} ${flight.flightCode}'),
                _DetailRow(label: 'Route', value: '${flight.origin} → ${flight.destination}'),
                _DetailRow(
                  label: 'Departure',
                  value: '${DateFormat('dd MMM yyyy').format(flight.departureTime)} at ${DateFormat('HH:mm').format(flight.departureTime)}',
                ),
                _DetailRow(
                  label: 'Arrival',
                  value: '${DateFormat('dd MMM yyyy').format(flight.arrivalTime)} at ${DateFormat('HH:mm').format(flight.arrivalTime)}',
                ),
                _DetailRow(label: 'Duration', value: flight.duration),
                _DetailRow(label: 'Stops', value: flight.stopsText),
                if (flight.aircraft.isNotEmpty)
                  _DetailRow(label: 'Aircraft', value: flight.aircraft),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Travellers',
                  value: '${booking.passengers.length}',
                ),
                if (booking.passengers.isNotEmpty)
                  ...booking.passengers.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      child: Text(
                        p.fullName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                if (booking.contactEmail.isNotEmpty)
                  _DetailRow(label: 'Email', value: booking.contactEmail),
                if (booking.contactPhone.isNotEmpty)
                  _DetailRow(label: 'Phone', value: booking.contactPhone),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Total Paid',
                  value: '${booking.currency} ${booking.totalPrice.toStringAsFixed(2)}',
                  valueStyle: AppTextStyles.price,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
