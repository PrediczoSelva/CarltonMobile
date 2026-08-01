import '../../domain/entities/booking.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remoteDatasource);

  final BookingRemoteDatasource _remoteDatasource;

  @override
  Future<Booking> createBooking({
    required int flightId,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    required String? paymentMethod,
  }) async {
    final request = BookingRequest(
      flightId: flightId,
      passengers: passengers,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      paymentMethod: paymentMethod,
    );
    return _remoteDatasource.createBooking(request);
  }

  @override
  Future<List<Booking>> getUserBookings() {
    return _remoteDatasource.getUserBookings();
  }

  @override
  Future<Booking?> getBookingById(int id) {
    return _remoteDatasource.getBookingById(id);
  }

  @override
  Future<void> cancelBooking(int id) {
    return _remoteDatasource.cancelBooking(id);
  }
}
