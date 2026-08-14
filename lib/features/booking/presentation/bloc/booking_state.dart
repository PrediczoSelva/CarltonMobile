import '../../domain/entities/booking.dart';

sealed class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  BookingSuccess(this.booking);

  final Booking booking;
}

class BookingError extends BookingState {
  BookingError(this.message);

  final String message;
}

class BookingsListLoaded extends BookingState {
  BookingsListLoaded(this.bookings);

  final List<Booking> bookings;
}

class BookingCancelled extends BookingState {
  BookingCancelled(this.bookingId);

  final int bookingId;
}
