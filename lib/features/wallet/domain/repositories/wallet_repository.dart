import '../entities/wallet_balance.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<WalletBalance> getWalletSummary();
  Future<List<WalletTransaction>> getTransactions();
  Future<String> createTopUpPaymentIntent({
    required double amount,
    required String currency,
    int? savedCardId,
  });
  Future<void> confirmTopUp({required String paymentIntentId});
}
