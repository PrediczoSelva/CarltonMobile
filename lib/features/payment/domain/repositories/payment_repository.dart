import '../../domain/entities/payment_intent.dart';

abstract class PaymentRepository {
  Future<PaymentIntent> createFlightPaymentIntent({
    required int flightId,
    required double amount,
    String? summary,
  });
}
