class CarSearchCriteria {
  const CarSearchCriteria({
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.sameDropoff,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
    required this.driverAge,
    this.promoCode,
  });

  final String pickupLocation;
  final String dropoffLocation;
  final bool sameDropoff;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupTime;
  final String returnTime;
  final int driverAge;
  final String? promoCode;

  int get rentalDays => returnDate.difference(pickupDate).inDays.clamp(1, 365);
}
