import '../entities/wallet_balance.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<WalletBalance> getWalletSummary();
  Future<List<WalletTransaction>> getTransactions();
}
