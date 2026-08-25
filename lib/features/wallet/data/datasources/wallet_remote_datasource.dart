import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';

abstract class WalletRemoteDatasource {
  Future<WalletBalance> getWalletSummary();
  Future<List<WalletTransaction>> getTransactions();
  Future<String> createTopUpPaymentIntent({
    required double amount,
    required String currency,
    int? savedCardId,
  });
  Future<void> confirmTopUp({required String paymentIntentId});
  Future<Map<String, dynamic>> getRedemptionConfig();
  Future<void> redeemPoints({required int pointsToRedeem});
}
