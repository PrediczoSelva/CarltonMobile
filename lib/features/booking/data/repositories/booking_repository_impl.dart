import '../../domain/entities/booking.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../../../core/utils/country_code_mapper.dart';
import '../models/atlas_verify_response.dart';
import '../models/amadeus_verify_response.dart';
import '../models/travelport_verify_response.dart';
import '../models/e_ticket_models.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remoteDatasource);

  final BookingRemoteDatasource _remoteDatasource;

  int _amadeusPassengerType(Passenger p) {
    final type = p.passengerType ?? Passenger.adultType;
    if (type == Passenger.infantType) return 2;
    if (type == Passenger.childType) return 1;
    return 0;
  }

  String _travelportPassengerType(Passenger p) {
    final type = p.passengerType ?? Passenger.adultType;
    if (type == Passenger.infantType) return 'INF';
    if (type == Passenger.childType) return 'CHD';
    return 'ADT';
  }

  @override
  Future<Booking> createBooking({
    required int flightId,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    String? paymentMethod,
    String? paymentMetadataJson,
  }) async {
    final request = BookingRequest.fromPassengers(
      flightId: flightId,
      passengers: passengers,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      paymentMethod: paymentMethod,
      paymentMetadataJson: paymentMetadataJson,
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

  @override
  Future<AtlasVerifyResponse> atlasVerify({
    required String routingIdentifier,
    required int adultCount,
    required int childCount,
    required int infantCount,
  }) {
    return _remoteDatasource.atlasVerify(
      routingIdentifier: routingIdentifier,
      adultCount: adultCount,
      childCount: childCount,
      infantCount: infantCount,
    );
  }

  @override
  Future<AmadeusVerifyResponse> amadeusVerify({
    required String amadeusOfferToken,
    required int adultCount,
    required int childCount,
    required int infantCount,
  }) {
    return _remoteDatasource.amadeusVerify(
      amadeusOfferToken: amadeusOfferToken,
      adultCount: adultCount,
      childCount: childCount,
      infantCount: infantCount,
    );
  }

  @override
  Future<TravelportVerifyResponse> travelportVerify({
    required String fareKey,
    required int adults,
    required int children,
    required int infants,
  }) {
    return _remoteDatasource.travelportVerify(
      fareKey: fareKey,
      adults: adults,
      children: children,
      infants: infants,
    );
  }

  @override
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
  }) async {
    final atlasPassengers = passengers.map((p) {
      final nameParts = '${p.firstName} ${p.lastName}'.trim().split(' ');
      final given = nameParts.isNotEmpty ? nameParts.first : '';
      final family = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final birthday = p.dateOfBirth != null
          ? '${p.dateOfBirth!.day.toString().padLeft(2, '0')}${p.dateOfBirth!.month.toString().padLeft(2, '0')}${p.dateOfBirth!.year}'
          : '';
      return {
        'name': '$family/$given',
        'passengerType': _amadeusPassengerType(p),
        'gender': 'M',
        'birthday': birthday,
        if (p.country != null) 'nationality': CountryCodeMapper.toIsoCodeOrDefault(p.country),
      };
    }).toList();

    final verify = await _remoteDatasource.atlasVerify(
      routingIdentifier: routingIdentifier,
      adultCount: passengers.length,
      childCount: 0,
      infantCount: 0,
    );

    return _remoteDatasource.atlasBook(
      sessionId: verify.sessionId,
      routingIdentifier: routingIdentifier,
      passengers: atlasPassengers,
      contact: {
        'name': contactName,
        'email': contactEmail,
        'mobile': contactPhone,
        'address': 'N/A',
        'postcode': '',
      },
      bookingClass: bookingClass,
      quotedTotal: quotedTotal,
      flightSnapshotJson: flightSnapshotJson,
      stripePaymentIntentId: stripePaymentIntentId,
      isGuest: isGuest,
    );
  }

  @override
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
    String? paypalOrderId,
    String? paypalCaptureId,
    bool payWithWallet = false,
    int? walletUserId,
    String? barclaycardReference,
    String? barclaycardLast4,
  }) async {
    final amadeusPassengers = passengers.map((p) {
      final birthday = p.dateOfBirth != null
          ? '${p.dateOfBirth!.day.toString().padLeft(2, '0')}${_monthAbbrev(p.dateOfBirth!.month)}${p.dateOfBirth!.year.toString().substring(2)}'
          : '';
      return {
        'firstName': p.firstName,
        'lastName': p.lastName,
        'passengerType': _amadeusPassengerType(p),
        'gender': 'M',
        'birthday': birthday,
        if (p.country != null) 'nationality': CountryCodeMapper.toIsoCodeOrDefault(p.country),
        if (p.passportNumber != null && p.passportNumber!.isNotEmpty) 'passportNumber': p.passportNumber,
        if (p.passportExpiry != null) 'passportExpiry': '${p.passportExpiry!.year.toString().padLeft(4, '0')}-${p.passportExpiry!.month.toString().padLeft(2, '0')}-${p.passportExpiry!.day.toString().padLeft(2, '0')}',
      };
    }).toList();

    final verify = await _remoteDatasource.amadeusVerify(
      amadeusOfferToken: amadeusOfferToken,
      adultCount: passengers.length,
      childCount: 0,
      infantCount: 0,
    );

    return _remoteDatasource.amadeusBook(
      amadeusOfferToken: amadeusOfferToken,
      verifyId: verify.verifyId,
      stripePaymentIntentId: stripePaymentIntentId,
      baseFareTotal: baseFareTotal,
      passengers: amadeusPassengers,
      contact: {
        'email': contactEmail,
        'mobile': contactPhone,
      },
      bookingClass: bookingClass,
      quotedTotal: quotedTotal,
      flightSnapshotJson: flightSnapshotJson,
      isGuest: isGuest,
      paypalOrderId: paypalOrderId,
      paypalCaptureId: paypalCaptureId,
      payWithWallet: payWithWallet,
      walletUserId: walletUserId,
      barclaycardReference: barclaycardReference,
      barclaycardLast4: barclaycardLast4,
    );
  }

  @override
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
  }) async {
    final travelportPassengers = passengers.map((p) {
      return {
        'title': 'Mr',
        'firstName': p.firstName,
        'lastName': p.lastName,
        'dateOfBirth': p.dateOfBirth != null
            ? '${p.dateOfBirth!.year}-${p.dateOfBirth!.month.toString().padLeft(2, '0')}-${p.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : '',
        'passportNumber': p.passportNumber ?? '',
        'nationality': CountryCodeMapper.toIsoCodeOrDefault(p.country),
        'passengerType': _travelportPassengerType(p),
      };
    }).toList();

    final verify = await _remoteDatasource.travelportVerify(
      fareKey: fareKey,
      adults: passengers.length,
      children: 0,
      infants: 0,
    );

    return _remoteDatasource.travelportBook(
      fareKey: verify.fareKey.isNotEmpty ? verify.fareKey : fareKey,
      segmentKeys: segmentKeys,
      passengers: travelportPassengers,
      contact: {
        'phone': contactPhone,
        'email': contactEmail,
      },
      bookingClass: bookingClass,
      quotedTotal: quotedTotal,
      providerBaseFare: providerBaseFare,
      flightSnapshotJson: flightSnapshotJson,
      stripePaymentIntentId: stripePaymentIntentId,
      isGuest: isGuest,
    );
  }

  @override
  Future<Booking> finalizeBookingPayment({
    required int bookingId,
    required String stripePaymentIntentId,
    String? paymentMetadataJson,
  }) async {
    return _remoteDatasource.finalizeBookingPayment(
      bookingId: bookingId,
      stripePaymentIntentId: stripePaymentIntentId,
      paymentMetadataJson: paymentMetadataJson,
    );
  }

  @override
  Future<ETicketData> getETicketStatus(int bookingId) {
    return _remoteDatasource.getETicketStatus(bookingId);
  }

  @override
  Future<ETicketData> downloadETicket(int bookingId) {
    return _remoteDatasource.downloadETicket(bookingId);
  }

  String _monthAbbrev(int month) {
    const abbr = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return abbr[month - 1];
  }
}
