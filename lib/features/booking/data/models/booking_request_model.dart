import '../../domain/entities/passenger.dart';

class BookingRequest {
  BookingRequest({
    required this.flightId,
    required this.passengerNames,
    required this.seatsBooked,
    required this.contactEmail,
    required this.contactPhone,
    this.paymentMethod,
    this.paymentMetadataJson,
  });

  final int flightId;
  final String passengerNames;
  final int seatsBooked;
  final String contactEmail;
  final String contactPhone;
  final String? paymentMethod;
  final String? paymentMetadataJson;

  factory BookingRequest.fromPassengers({
    required int flightId,
    required List<Passenger> passengers,
    required String contactEmail,
    required String contactPhone,
    String? paymentMethod,
    String? paymentMetadataJson,
  }) {
    final names = passengers.map((p) => '${p.firstName} ${p.lastName}').toList();
    return BookingRequest(
      flightId: flightId,
      passengerNames: names.join(', '),
      seatsBooked: passengers.length,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      paymentMethod: paymentMethod,
      paymentMetadataJson: paymentMetadataJson,
    );
  }

  Map<String, dynamic> toJson() => {
        'flightId': flightId,
        'passengerNames': passengerNames,
        'seatsBooked': seatsBooked,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentMetadataJson != null) 'paymentMetadataJson': paymentMetadataJson,
      };
}
