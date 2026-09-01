class TravelportVerifyResponse {
  const TravelportVerifyResponse({
    required this.fareKey,
    required this.currency,
    required this.quotedTotal,
  });

  factory TravelportVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TravelportVerifyResponse(
      fareKey: json['fareKey'] as String? ??
          json['FareKey'] as String? ??
          '',
      currency: json['currency'] as String? ??
          json['Currency'] as String? ??
          'GBP',
      quotedTotal: (json['totalPrice'] as num?)?.toDouble() ??
          (json['TotalPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          (json['Price'] as num?)?.toDouble() ??
          0.0,
    );
  }

  final String fareKey;
  final String currency;
  final double quotedTotal;
}
