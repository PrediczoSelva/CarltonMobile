class WalletBalance {
  const WalletBalance({
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

  double get pointsValueEquivalent => loyaltyPoints * 0.01;
}
