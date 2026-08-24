import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';

sealed class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoadedState extends WalletState {
  WalletLoadedState({
    required this.balance,
    required this.transactions,
  });

  final WalletBalance balance;
  final List<WalletTransaction> transactions;
}

class WalletError extends WalletState {
  WalletError(this.message);

  final String message;
}
