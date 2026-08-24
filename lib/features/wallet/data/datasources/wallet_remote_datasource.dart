import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';

abstract class WalletRemoteDatasource {
  Future<WalletBalance> getWalletSummary();
  Future<List<WalletTransaction>> getTransactions();
}
