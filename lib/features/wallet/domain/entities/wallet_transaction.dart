class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final DateTime createdAt;
}

enum WalletTransactionType {
  topUp,
  redemption,
  debit,
  refund,
}

extension WalletTransactionTypeLabel on WalletTransactionType {
  String get label {
    switch (this) {
      case WalletTransactionType.topUp:
        return 'Top Up';
      case WalletTransactionType.redemption:
        return 'Redemption';
      case WalletTransactionType.debit:
        return 'Debit';
      case WalletTransactionType.refund:
        return 'Refund';
    }
  }
}
