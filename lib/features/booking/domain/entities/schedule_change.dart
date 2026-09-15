class ScheduleChange {
  const ScheduleChange({
    required this.bookingId,
    required this.pnr,
    required this.reason,
    required this.originalDepartureTime,
    required this.originalArrivalTime,
    required this.newDepartureTime,
    required this.newArrivalTime,
    required this.newFlightCode,
    required this.newAirline,
    required this.oldFlightCode,
    required this.oldAirline,
    required this.priceChange,
    required this.currency,
    required this.message,
    required this.createdAt,
    this.accepted = false,
  });

  factory ScheduleChange.fromJson(Map<String, dynamic> json) {
    return ScheduleChange(
      bookingId: (json['bookingId'] ?? json['id'] ?? 0) as int,
      pnr: json['pnr'] as String? ?? '',
      reason: json['reason'] as String? ?? 'Schedule change',
      originalDepartureTime: DateTime.tryParse(
              json['originalDepartureTime'] as String? ??
                  json['oldDepartureTime'] as String? ??
                  '') ??
          DateTime.now(),
      originalArrivalTime: DateTime.tryParse(
              json['originalArrivalTime'] as String? ??
                  json['oldArrivalTime'] as String? ??
                  '') ??
          DateTime.now(),
      newDepartureTime: DateTime.tryParse(
              json['newDepartureTime'] as String? ?? '') ??
          DateTime.now(),
      newArrivalTime: DateTime.tryParse(
              json['newArrivalTime'] as String? ?? '') ??
          DateTime.now(),
      newFlightCode: json['newFlightCode'] as String? ??
          json['newFlightNumber'] as String? ??
          '',
      newAirline: json['newAirline'] as String? ??
          json['newAirlineName'] as String? ??
          '',
      oldFlightCode: json['oldFlightCode'] as String? ??
          json['oldFlightNumber'] as String? ??
          '',
      oldAirline: json['oldAirline'] as String? ??
          json['oldAirlineName'] as String? ??
          '',
      priceChange: (json['priceChange'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      accepted: (json['accepted'] as bool?) ?? false,
    );
  }

  final int bookingId;
  final String pnr;
  final String reason;
  final DateTime originalDepartureTime;
  final DateTime originalArrivalTime;
  final DateTime newDepartureTime;
  final DateTime newArrivalTime;
  final String newFlightCode;
  final String newAirline;
  final String oldFlightCode;
  final String oldAirline;
  final double priceChange;
  final String currency;
  final String message;
  final DateTime createdAt;
  final bool accepted;
}
