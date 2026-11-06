/// Returned by the API when a correct username/password still needs a
/// second factor (a one-time code sent to the user's email).
class MfaChallenge {
  const MfaChallenge({
    required this.challengeToken,
    this.maskedEmail,
    this.expiresAt,
  });

  /// `tempToken` from POST /Auth/login; sent back with the code to
  /// POST /Auth/2fa/verify.
  final String challengeToken;

  /// e.g. "du****@gmail.com" – where the code was sent.
  final String? maskedEmail;

  /// When the code stops being valid (if the API tells us).
  final DateTime? expiresAt;

  factory MfaChallenge.fromJson(Map<String, dynamic> json) {
    // Backend (feature/2FA) returns the pending token as `tempToken`.
    final token = (json['tempToken'] ??
            json['mfaToken'] ??
            json['challengeToken']) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Verification could not be started. Please try again.');
    }
    final expires = json['expiresAt'] ?? json['mfaExpiresAt'];
    return MfaChallenge(
      challengeToken: token,
      maskedEmail: (json['maskedEmail'] ?? json['email']) as String?,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  }
}
