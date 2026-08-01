import '../../domain/entities/passenger.dart';

class BookingRequest {
  BookingRequest({
    required this.flightId,
    required this.passengers,
    required this.contactEmail,
    required this.contactPhone,
    this.paymentMethod,
  });

  final int flightId;
  final List<Passenger> passengers;
  final String contactEmail;
  final String contactPhone;
  final String? paymentMethod;

  Map<String, dynamic> toJson() => {
        'flightId': flightId,
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      };
}
