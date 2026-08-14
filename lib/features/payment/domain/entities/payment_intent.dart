class PaymentIntent {
  const PaymentIntent({
    required this.clientSecret,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      clientSecret: json['clientSecret'] as String? ?? '',
    );
  }

  final String clientSecret;

  Map<String, dynamic> toJson() => {
        'clientSecret': clientSecret,
      };
}
