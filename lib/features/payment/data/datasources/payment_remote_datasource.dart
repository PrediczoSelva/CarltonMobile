import '../../domain/entities/payment_intent.dart';

abstract class PaymentRemoteDatasource {
  Future<PaymentIntent> createFlightPaymentIntent({
    required int flightId,
    required double amount,
    String? summary,
  });
}
