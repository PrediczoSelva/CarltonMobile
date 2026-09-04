import '../models/atlas_verify_response.dart';
import '../models/amadeus_verify_response.dart';
import '../models/travelport_verify_response.dart';
import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import '../models/e_ticket_models.dart';

abstract class BookingRemoteDatasource {
  Future<BookingModel> createBooking(BookingRequest request);
  Future<List<BookingModel>> getUserBookings();
  Future<BookingModel?> getBookingById(int id);
  Future<void> cancelBooking(int id);

  Future<AtlasVerifyResponse> atlasVerify({
    required String routingIdentifier,
    required int adultCount,
    required int childCount,
    required int infantCount,
  });
  Future<BookingModel> atlasBook({
    required String sessionId,
    required String routingIdentifier,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
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
  Future<BookingModel> amadeusBook({
    required String amadeusOfferToken,
    required String verifyId,
    required String stripePaymentIntentId,
    required double baseFareTotal,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
    required String bookingClass,
    required double quotedTotal,
    String? flightSnapshotJson,
    bool isGuest = false,
    String? paypalOrderId,
    String? paypalCaptureId,
    bool payWithWallet = false,
    int? walletUserId,
    String? barclaycardReference,
    String? barclaycardLast4,
  });

  Future<TravelportVerifyResponse> travelportVerify({
    required String fareKey,
    required int adults,
    required int children,
    required int infants,
  });
  Future<BookingModel> travelportBook({
    required String fareKey,
    required List<String> segmentKeys,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> contact,
    required String bookingClass,
    required double quotedTotal,
    double providerBaseFare = 0,
    String? flightSnapshotJson,
    String? stripePaymentIntentId,
    bool isGuest = false,
  });

  Future<BookingModel> finalizeBookingPayment({
    required int bookingId,
    required String stripePaymentIntentId,
    String? paymentMetadataJson,
  });

  Future<ETicketData> getETicketStatus(int bookingId);
  Future<ETicketData> downloadETicket(int bookingId);
}
