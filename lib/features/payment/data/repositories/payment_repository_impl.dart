import '../../domain/entities/payment_intent.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remoteDatasource);

  final PaymentRemoteDatasource _remoteDatasource;

  @override
  Future<PaymentIntent> createFlightPaymentIntent({
    required int flightId,
    required double amount,
    String? summary,
  }) {
    return _remoteDatasource.createFlightPaymentIntent(
      flightId: flightId,
      amount: amount,
      summary: summary,
    );
  }
}
