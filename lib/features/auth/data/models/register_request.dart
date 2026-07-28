class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneCountryCode;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? nationality;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneCountryCode,
    this.phoneNumber,
    this.dateOfBirth,
    this.nationality,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneCountryCode': phoneCountryCode,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'nationality': nationality,
    };
  }
}