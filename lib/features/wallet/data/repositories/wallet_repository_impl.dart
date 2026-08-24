import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remoteDatasource);

  final WalletRemoteDatasource _remoteDatasource;

  @override
  Future<WalletBalance> getWalletSummary() {
    return _remoteDatasource.getWalletSummary();
  }

  @override
  Future<List<WalletTransaction>> getTransactions() {
    return _remoteDatasource.getTransactions();
  }

  @override
  Future<String> createTopUpPaymentIntent({
    required double amount,
    required String currency,
    int? savedCardId,
  }) {
    return _remoteDatasource.createTopUpPaymentIntent(
      amount: amount,
      currency: currency,
      savedCardId: savedCardId,
    );
  }

  @override
  Future<void> confirmTopUp({required String paymentIntentId}) {
    return _remoteDatasource.confirmTopUp(paymentIntentId: paymentIntentId);
  }
}
