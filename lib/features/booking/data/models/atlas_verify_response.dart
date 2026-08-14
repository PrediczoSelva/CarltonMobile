class AtlasVerifyResponse {
  const AtlasVerifyResponse({
    required this.sessionId,
    required this.currency,
    required this.priceChanged,
    required this.quotedTotal,
  });

  factory AtlasVerifyResponse.fromJson(Map<String, dynamic> json) {
    final quote = json['quote'] as Map<String, dynamic>? ?? {};
    final total = quote['total'] ?? quote['quotedTotal'] ?? 0;
    return AtlasVerifyResponse(
      sessionId: json['sessionId'] as String? ?? '',
      currency: json['currency'] as String? ?? 'GBP',
      priceChanged: json['priceChanged'] as bool? ?? false,
      quotedTotal: (total as num?)?.toDouble() ?? 0.0,
    );
  }

  final String sessionId;
  final String currency;
  final bool priceChanged;
  final double quotedTotal;
}
