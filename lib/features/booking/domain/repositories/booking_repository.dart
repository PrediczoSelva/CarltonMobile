import '../entities/booking.dart';
import '../entities/passenger.dart';
import '../../data/models/atlas_verify_response.dart';
import '../../data/models/amadeus_verify_response.dart';
import '../../data/models/travelport_verify_response.dart';

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

  Future<AtlasVerifyResponse> atlasVerify({
    required String routingIdentifier,
    required int adultCount,
    required int childCount,
    required int infantCount,
  });

  Future<Booking> createAtlasBooking({
    required String routingIdentifier,
    required List<Passenger> passengers,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required String bookingClass,
    required double quotedTotal,
    String? flightSnapshotJson,
    String? stripePaymentIntentId,
    bool isGuest = false,
  });

  Future<AmadeusVerifyResponse> amadeusVerify({
    required String amadeusOfferToken,
    required int adultCount,
    required int childCount,
    required int infantCount,
  });

  Future<Booking> createAmadeusBooking({
    required String amadeusOfferToken,
    required String verifyId,
    required String stripePaymentIntentId,
    required double baseFareTotal,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    required String bookingClass,
    required double quotedTotal,
    String? flightSnapshotJson,
    bool isGuest = false,
  });

  Future<TravelportVerifyResponse> travelportVerify({
    required String fareKey,
    required int adults,
    required int children,
    required int infants,
  });

  Future<Booking> createTravelportBooking({
    required String fareKey,
    required List<String> segmentKeys,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    required String bookingClass,
    required double quotedTotal,
    double providerBaseFare = 0,
    String? flightSnapshotJson,
    String? stripePaymentIntentId,
    bool isGuest = false,
  });
}
