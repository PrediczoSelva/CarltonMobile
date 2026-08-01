import '../models/booking_model.dart';
import '../models/booking_request_model.dart';

abstract class BookingRemoteDatasource {
  Future<BookingModel> createBooking(BookingRequest request);
  Future<List<BookingModel>> getUserBookings();
  Future<BookingModel?> getBookingById(int id);
  Future<void> cancelBooking(int id);
}
