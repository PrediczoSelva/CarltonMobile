class FlightSearchCriteria {
  const FlightSearchCriteria({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.passengers = 1,
  });

  final String origin;
  final String destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int passengers;

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'destination': destination,
        'departureDate': departureDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'passengers': passengers,
      };

  String get originCode {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(origin);
    return match != null ? match.group(1)! : origin;
  }

  String get destinationCode {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(destination);
    return match != null ? match.group(1)! : destination;
  }
}
