import '../../../flight/domain/entities/flight.dart';
import 'passenger.dart';

class Booking {
  const Booking({
    required this.id,
    required this.pnr,
    required this.flight,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.bookingDate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int? ?? 0,
      pnr: json['pnr'] as String? ?? '',
      flight: Flight.fromJson(json['flight'] as Map<String, dynamic>),
      passengers: (json['passengers'] as List<dynamic>?)
              ?.map((p) => Passenger.fromJson(p as Map<String, dynamic>))
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

  final int id;
  final String pnr;
  final Flight flight;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final double totalPrice;
  final String currency;
  final String status;
  final DateTime bookingDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pnr': pnr,
        'flight': flight.toJson(),
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'totalPrice': totalPrice,
        'currency': currency,
        'status': status,
        'bookingDate': bookingDate.toIso8601String(),
      };

  static List<Booking> filterByStatus(
    List<Booking> bookings, {
    String? status,
  }) {
    if (status == null || status.isEmpty) return List.of(bookings);
    final lower = status.toLowerCase();
    return bookings.where((b) => b.status.toLowerCase() == lower).toList();
  }

  static List<Booking> filterByDate(List<Booking> bookings,
      {DateTime? from, DateTime? to}) {
    final start = from ?? DateTime.fromMillisecondsSinceEpoch(0);
    final end = to ?? DateTime.now();
    return bookings
        .where((b) =>
            b.flight.departureTime.isAfter(start) &&
            b.flight.departureTime.isBefore(end))
        .toList();
  }

  static List<Booking> filterUpcoming(List<Booking> bookings,
      {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return bookings
        .where((b) =>
            !b.status.toLowerCase().contains('cancel') &&
            b.flight.departureTime.isAfter(reference))
        .toList();
  }

  static List<Booking> filterPast(List<Booking> bookings, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return bookings
        .where((b) =>
            !b.status.toLowerCase().contains('cancel') &&
            b.flight.departureTime.isBefore(reference))
        .toList();
  }

  static List<Booking> filterCancelled(List<Booking> bookings) {
    return bookings
        .where((b) => b.status.toLowerCase().contains('cancel'))
        .toList();
  }
}
