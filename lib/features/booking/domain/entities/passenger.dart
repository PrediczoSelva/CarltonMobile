class Passenger {
  static const int adultType = 0;
  static const int childType = 1;
  static const int infantType = 2;

  const Passenger({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.passportNumber,
    this.passportExpiry,
    this.country,
    this.passengerType,
  });

  final int? passengerType;

  final int? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? passportNumber;
  final DateTime? passportExpiry;
  final String? country;

  Passenger copyWith({
    int? id,
    String? firstName,
    String lastName = '',
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? passportNumber,
    DateTime? passportExpiry,
    String? country,
    int? passengerType,
  }) {
    return Passenger(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName.isEmpty ? this.lastName : lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      country: country ?? this.country,
      passengerType: passengerType ?? this.passengerType,
    );
  }

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
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
      passengerType: json['passengerType'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'firstName': firstName,
        'lastName': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        if (passportNumber != null) 'passportNumber': passportNumber,
        if (passportExpiry != null) 'passportExpiry': passportExpiry!.toIso8601String(),
        if (country != null) 'country': country,
        if (passengerType != null) 'passengerType': passengerType,
      };

  String get fullName => '$firstName $lastName';
}
