class HotelSearchCriteria {
  const HotelSearchCriteria({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    this.adults = 1,
    this.children = 0,
    this.rooms = 1,
    this.currency = 'GBP',
    this.limit = 20,
    this.offset = 0,
  });

  final String destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int rooms;
  final String currency;
  final int limit;
  final int offset;
}
