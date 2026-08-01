class Flight {
  const Flight({
    required this.id,
    required this.airline,
    required this.flightCode,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.stops,
    required this.stopLocations,
    required this.price,
    required this.currency,
    required this.aircraft,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] as int? ?? 0,
      airline: json['airline'] as String? ?? '',
      flightCode: json['flightCode'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime:
          DateTime.tryParse(json['departureTime'] as String? ?? '') ?? DateTime.now(),
      arrivalTime: DateTime.tryParse(json['arrivalTime'] as String? ?? '') ?? DateTime.now(),
      duration: json['duration'] as String? ?? '',
      stops: json['stops'] as int? ?? 0,
      stopLocations:
          (json['stopLocations'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      aircraft: json['aircraft'] as String? ?? '',
    );
  }

  final int id;
  final String airline;
  final String flightCode;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String duration;
  final int stops;
  final List<String> stopLocations;
  final double price;
  final String currency;
  final String aircraft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'airline': airline,
        'flightCode': flightCode,
        'origin': origin,
        'destination': destination,
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'duration': duration,
        'stops': stops,
        'stopLocations': stopLocations,
        'price': price,
        'currency': currency,
        'aircraft': aircraft,
      };

  String get stopsText => stops == 0 ? 'Non-stop' : '$stops stop${stops > 1 ? 's' : ''}';

  @override
  String toString() => '$airline $flightCode ($origin → $destination)';
}
