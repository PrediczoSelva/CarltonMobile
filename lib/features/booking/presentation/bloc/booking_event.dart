import '../../domain/entities/passenger.dart';

sealed class BookingEvent {}

class CreateBookingRequested extends BookingEvent {
  CreateBookingRequested({
    required this.flightId,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    this.paymentMethod,
    this.paymentMetadataJson,
  });

  final int flightId;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final String? paymentMethod;
  final String? paymentMetadataJson;
}

class CreateAtlasBookingRequested extends BookingEvent {
  CreateAtlasBookingRequested({
    required this.routingIdentifier,
    required this.passengers,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.bookingClass,
    required this.quotedTotal,
    this.flightSnapshotJson,
    this.stripePaymentIntentId,
    this.isGuest = false,
  });

  final String routingIdentifier;
  final List<Passenger> passengers;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String bookingClass;
  final double quotedTotal;
  final String? flightSnapshotJson;
  final String? stripePaymentIntentId;
  final bool isGuest;
}

class CreateAmadeusBookingRequested extends BookingEvent {
  CreateAmadeusBookingRequested({
    required this.amadeusOfferToken,
    required this.verifyId,
    required this.stripePaymentIntentId,
    required this.baseFareTotal,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    required this.bookingClass,
    required this.quotedTotal,
    this.flightSnapshotJson,
    this.isGuest = false,
    this.paypalOrderId,
    this.paypalCaptureId,
    this.payWithWallet = false,
    this.walletUserId,
    this.barclaycardReference,
    this.barclaycardLast4,
  });

  final String amadeusOfferToken;
  final String verifyId;
  final String stripePaymentIntentId;
  final double baseFareTotal;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final String bookingClass;
  final double quotedTotal;
  final String? flightSnapshotJson;
  final bool isGuest;
  final String? paypalOrderId;
  final String? paypalCaptureId;
  final bool payWithWallet;
  final int? walletUserId;
  final String? barclaycardReference;
  final String? barclaycardLast4;
}

class CreateTravelportBookingRequested extends BookingEvent {
  CreateTravelportBookingRequested({
    required this.fareKey,
    required this.segmentKeys,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    required this.bookingClass,
    required this.quotedTotal,
    this.providerBaseFare = 0,
    this.flightSnapshotJson,
    this.stripePaymentIntentId,
    this.isGuest = false,
  });

  final String fareKey;
  final List<String> segmentKeys;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final String bookingClass;
  final double quotedTotal;
  final double providerBaseFare;
  final String? flightSnapshotJson;
  final String? stripePaymentIntentId;
  final bool isGuest;
}

class GetUserBookingsRequested extends BookingEvent {}

class CancelBookingRequested extends BookingEvent {
  CancelBookingRequested(this.bookingId);

  final int bookingId;
}
