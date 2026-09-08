class FlightSearchCriteria {
  const FlightSearchCriteria({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.passengers = 1,
    this.cabinClass = 'Economy',
  });

  final String origin;
  final String destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int passengers;
  final String cabinClass;

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'destination': destination,
        'departureDate': departureDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'passengers': passengers,
        'cabinClass': cabinClass,
      };

  String get originCode {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(origin);
    return match != null ? match.group(1)! : origin;
  }

  String get destinationCode {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(destination);
    return match != null ? match.group(1)! : destination;
  }

  String get originCity {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(origin);
    return match != null ? origin.substring(0, match.start).trim() : origin;
  }

  String get destinationCity {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(destination);
    return match != null ? destination.substring(0, match.start).trim() : destination;
  }
}
