import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/wallet_repository.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc(this._repository) : super(WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
  }

  final WalletRepository _repository;

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final results = await Future.wait([
        _repository.getWalletSummary(),
        _repository.getTransactions(),
      ]);
      emit(WalletLoadedState(
        balance: results[0] as WalletBalance,
        transactions: results[1] as List<WalletTransaction>,
      ));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
