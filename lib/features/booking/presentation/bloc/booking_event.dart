import '../../domain/entities/passenger.dart';

sealed class BookingEvent {}

class CreateBookingRequested extends BookingEvent {
  CreateBookingRequested({
    required this.flightId,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    this.paymentMethod,
  });

  final int flightId;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final String? paymentMethod;
}

class GetUserBookingsRequested extends BookingEvent {}

class CancelBookingRequested extends BookingEvent {
  CancelBookingRequested(this.bookingId);

  final int bookingId;
}
