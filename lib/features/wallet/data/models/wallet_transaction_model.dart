import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel {
  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'debit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WalletTransaction toEntity() {
    return WalletTransaction(
      id: id,
      type: _mapType(type),
      amount: amount,
      description: description,
      createdAt: createdAt,
    );
  }

  WalletTransactionType _mapType(String value) {
    switch (value.toLowerCase()) {
      case 'topup':
      case 'top_up':
        return WalletTransactionType.topUp;
      case 'redemption':
        return WalletTransactionType.redemption;
      case 'refund':
        return WalletTransactionType.refund;
      default:
        return WalletTransactionType.debit;
    }
  }
}
