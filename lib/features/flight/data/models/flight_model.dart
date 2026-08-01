import '../../domain/entities/flight.dart';

class FlightModel extends Flight {
  FlightModel({
    required super.id,
    required super.airline,
    required super.flightCode,
    required super.origin,
    required super.destination,
    required super.departureTime,
    required super.arrivalTime,
    required super.duration,
    required super.stops,
    required super.stopLocations,
    required super.price,
    required super.currency,
    required super.aircraft,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id'] as int? ?? 0,
      airline: json['airline'] as String? ?? '',
      flightCode: json['flightCode'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime:
          DateTime.tryParse(json['departureTime'] as String? ?? '') ?? DateTime.now(),
      arrivalTime:
          DateTime.tryParse(json['arrivalTime'] as String? ?? '') ?? DateTime.now(),
      duration: json['duration'] as String? ?? '',
      stops: json['stops'] as int? ?? 0,
      stopLocations:
          (json['stopLocations'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      aircraft: json['aircraft'] as String? ?? '',
    );
  }
}
