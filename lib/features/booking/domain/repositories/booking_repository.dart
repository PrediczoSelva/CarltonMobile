import '../entities/booking.dart';
import '../entities/passenger.dart';

abstract class BookingRepository {
  Future<Booking> createBooking({
    required int flightId,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    String? paymentMethod,
    String? paymentMetadataJson,
  });

  Future<List<Booking>> getUserBookings();
  Future<Booking?> getBookingById(int id);
  Future<void> cancelBooking(int id);
}
