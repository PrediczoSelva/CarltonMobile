import '../../domain/entities/wallet_balance.dart';

class WalletBalanceModel {
  WalletBalanceModel({
    required this.balance,
    required this.currencyCode,
    required this.loyaltyPoints,
    required this.tierLevel,
    required this.totalLifetimeSpend,
    required this.tripsCompleted,
  });

  final double balance;
  final String currencyCode;
  final int loyaltyPoints;
  final String tierLevel;
  final double totalLifetimeSpend;
  final int tripsCompleted;

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      tierLevel: json['tierLevel'] as String? ?? 'Bronze',
      totalLifetimeSpend: (json['totalLifetimeSpend'] as num?)?.toDouble() ?? 0.0,
      tripsCompleted: json['tripsCompleted'] as int? ?? 0,
    );
  }

  WalletBalance toEntity() {
    return WalletBalance(
      balance: balance,
      currencyCode: currencyCode,
      loyaltyPoints: loyaltyPoints,
      tierLevel: tierLevel,
      totalLifetimeSpend: totalLifetimeSpend,
      tripsCompleted: tripsCompleted,
    );
  }
}
