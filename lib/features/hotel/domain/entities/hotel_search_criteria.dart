class HotelSearchCriteria {
  const HotelSearchCriteria({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.rooms,
  });

  final String destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int rooms;

  int get nights => checkOut.difference(checkIn).inDays;
  int get guests => adults + children;
}
