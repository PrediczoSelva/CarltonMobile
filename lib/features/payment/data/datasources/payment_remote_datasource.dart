import '../../domain/entities/payment_intent.dart';

abstract class PaymentRemoteDatasource {
  Future<PaymentIntent> createFlightPaymentIntent({
    int? flightId,
    required double amount,
    String? summary,
  });
}
