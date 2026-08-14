import 'user_model.dart';

class LoginResponse {
  final UserModel user;
  final DateTime expiresAt;
  final int claimedBookingCount;

  LoginResponse({
    required this.user,
    required this.expiresAt,
    required this.claimedBookingCount,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      claimedBookingCount: json['claimedBookingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
      'claimedBookingCount': claimedBookingCount,
    };
  }
}