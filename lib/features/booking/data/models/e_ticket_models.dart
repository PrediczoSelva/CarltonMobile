class ETicketSegment {
  const ETicketSegment({
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.ticketNumber,
    this.flightClass,
    this.gate,
    this.airline,
  });

  factory ETicketSegment.fromJson(Map<String, dynamic> json) {
    return ETicketSegment(
      flightNumber: json['flightNumber'] as String? ?? json['flightCode'] as String? ?? '',
      origin: json['origin'] as String? ?? json['from'] as String? ?? '',
      destination: json['destination'] as String? ?? json['to'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? json['departsAt'] as String? ?? '',
      arrivalTime: json['arrivalTime'] as String? ?? json['arrivesAt'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String? ?? json['ticketNo'] as String? ?? '',
      flightClass: json['class'] as String? ?? json['bookingClass'] as String?,
      gate: json['gate'] as String?,
      airline: json['airline'] as String? ?? json['airlineName'] as String?,
    );
  }

  final String flightNumber;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String ticketNumber;
  final String? flightClass;
  final String? gate;
  final String? airline;

  Map<String, dynamic> toJson() => {
        'flightNumber': flightNumber,
        'origin': origin,
        'destination': destination,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'ticketNumber': ticketNumber,
        'class': flightClass,
        'gate': gate,
        'airline': airline,
      };
}

class ETicketData {
  const ETicketData({
    required this.issued,
    required this.ticketNumber,
    required this.issueDate,
    required this.airline,
    required this.pnr,
    required this.passengerName,
    required this.segments,
    this.totalAmount,
    this.currency,
  });

  factory ETicketData.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>? ?? [];
    return ETicketData(
      issued: json['issued'] as bool? ?? json['isIssued'] as bool? ?? false,
      ticketNumber: json['ticketNumber'] as String? ?? json['ticketNo'] as String? ?? '',
      issueDate: json['issueDate'] as String? ?? json['issuedAt'] as String? ?? '',
      airline: json['airline'] as String? ?? json['airlineName'] as String? ?? '',
      pnr: json['pnr'] as String? ?? json['PNR'] as String? ?? json['bookingReference'] as String? ?? '',
      passengerName: json['passengerName'] as String? ?? json['leadPassenger'] as String? ?? '',
      segments: segmentsJson
          .map((s) => ETicketSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['totalPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? json['currencyCode'] as String? ?? 'GBP',
    );
  }

  final bool issued;
  final String ticketNumber;
  final String issueDate;
  final String airline;
  final String pnr;
  final String passengerName;
  final List<ETicketSegment> segments;
  final double? totalAmount;
  final String? currency;

  Map<String, dynamic> toJson() => {
        'issued': issued,
        'ticketNumber': ticketNumber,
        'issueDate': issueDate,
        'airline': airline,
        'pnr': pnr,
        'passengerName': passengerName,
        'segments': segments.map((s) => s.toJson()).toList(),
        'totalAmount': totalAmount,
        'currency': currency,
      };
}
