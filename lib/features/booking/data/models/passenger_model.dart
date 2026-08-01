import '../../domain/entities/passenger.dart';

class PassengerModel extends Passenger {
  PassengerModel({
    super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.phone,
    super.dateOfBirth,
    super.passportNumber,
    super.passportExpiry,
    super.country,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      id: json['id'] as int?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      passportNumber: json['passportNumber'] as String?,
      passportExpiry: json['passportExpiry'] != null
          ? DateTime.tryParse(json['passportExpiry'] as String)
          : null,
      country: json['country'] as String?,
    );
  }
}
