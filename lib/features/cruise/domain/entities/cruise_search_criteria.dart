class CruiseSearchCriteria {
  const CruiseSearchCriteria({
    required this.destination,
    required this.departurePort,
    required this.departureMonth,
    required this.duration,
    required this.guests,
    required this.cabinsCount,
  });

  final String destination;
  final String departurePort;
  final String departureMonth;
  final String duration;
  final int guests;
  final int cabinsCount;
}
