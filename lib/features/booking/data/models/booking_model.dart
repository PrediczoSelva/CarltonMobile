import 'dart:convert';

import '../../domain/entities/booking.dart';
import '../../../flight/domain/entities/flight.dart';
import 'passenger_model.dart';

class BookingModel extends Booking {
  BookingModel({
    required super.id,
    required super.pnr,
    required super.flight,
    required super.passengers,
    required super.contactEmail,
    required super.contactPhone,
    required super.totalPrice,
    required super.currency,
    required super.status,
    required super.bookingDate,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final flightData = json['flight'] ?? json['flightSnapshotJson'];
    Map<String, dynamic>? flightJson;
    if (flightData is Map<String, dynamic>) {
      flightJson = flightData;
    } else if (flightData is String && flightData.isNotEmpty) {
      try {
        final parsed = jsonDecode(flightData);
        if (parsed is Map<String, dynamic>) {
          flightJson = parsed;
        }
      } catch (_) {
        flightJson = null;
      }
    }

    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final idValue = json['id'] ?? json['bookingId'] ?? json['booking_id'];
    final pnrValue = json['pnr'] ??
        json['PNR'] ??
        json['bookingReference'] ??
        json['bookingRef'];

    return BookingModel(
      id: parseId(idValue),
      pnr: pnrValue as String? ?? '',
      flight: flightJson != null
          ? Flight.fromJson(flightJson)
          : _flightFromBookingJson(json),
      passengers: (json['passengers'] as List<dynamic>?)
              ?.map((p) => PassengerModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      status: json['status'] as String? ?? 'Pending',
      bookingDate: json['bookingDate'] != null
          ? DateTime.tryParse(json['bookingDate'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Flight _flightFromBookingJson(Map<String, dynamic> json) {
    final parseId = int.tryParse('${json['flightId'] ?? 0}') ?? 0;
    return Flight(
      id: parseId,
      airline: json['airline'] as String? ?? '',
      flightCode: json['flightNumber'] as String? ?? '',
      origin: json['departure'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: DateTime.tryParse(json['departureTime'] as String? ?? '') ??
          DateTime.now(),
      arrivalTime:
          DateTime.tryParse(json['arrivalTime'] as String? ?? '') ??
          DateTime.now(),
      duration: json['duration'] as String? ?? '',
      stops: json['stops'] is int
          ? json['stops'] as int
          : int.tryParse('${json['stops']}') ?? 0,
      stopLocations: (json['stopLocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      price: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      aircraft: json['aircraft'] as String? ?? '',
    );
  }
}
