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
    final flightJson = json['flight'] as Map<String, dynamic>?;
    return BookingModel(
      id: json['id'] as int? ?? 0,
      pnr: json['pnr'] as String? ?? '',
      flight: flightJson != null ? Flight.fromJson(flightJson) : _fallbackFlight(),
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

  static Flight _fallbackFlight() => Flight(
        id: 0,
        airline: '',
        flightCode: '',
        origin: '',
        destination: '',
        departureTime: DateTime.now(),
        arrivalTime: DateTime.now(),
        duration: '',
        stops: 0,
        stopLocations: [],
        price: 0,
        currency: 'GBP',
        aircraft: '',
      );
}
