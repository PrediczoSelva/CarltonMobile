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
      balance: ((json['balance'] ??
              json['walletBalance'] ??
              json['availableBalance'] ??
              json['balanceAmount'] ??
              json['amount']) as num?)?.toDouble() ??
          0.0,
      currencyCode: json['currencyCode'] as String? ??
          json['currency'] as String? ??
          'GBP',
      loyaltyPoints: (json['loyaltyPoints'] ??
              json['points'] ??
              json['loyaltyPointsBalance'] ??
              json['pointsBalance']) as int? ??
          0,
      tierLevel: json['tierLevel'] as String? ??
          json['tier'] as String? ??
          'Bronze',
      totalLifetimeSpend: ((json['totalLifetimeSpend'] ??
              json['lifetimeSpend'] ??
              json['lifetimeValue']) as num?)?.toDouble() ??
          0.0,
      tripsCompleted: (json['tripsCompleted'] ??
              json['completedTrips'] ??
              json['bookingsCount'] ??
              json['bookingsCompleted']) as int? ??
          0,
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
