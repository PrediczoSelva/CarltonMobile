class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.currency,
    required this.starRating,
    required this.guestRating,
    required this.amenities,
    required this.refundable,
    required this.thumbnail,
  });

  final String id;
  final String name;
  final String location;
  final double price;
  final String currency;
  final int starRating;
  final double guestRating;
  final List<String> amenities;
  final bool refundable;
  final String? thumbnail;

  bool get hasBreakfast => amenities.any(
        (amenity) => amenity.toLowerCase().contains('breakfast'),
      );

  factory Hotel.fromJson(Map<String, dynamic> json) {
    dynamic value(String camel, String pascal) => json[camel] ?? json[pascal];
    double number(dynamic raw) =>
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    int integer(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

    final amenities = value('amenities', 'Amenities');
    return Hotel(
      id: '${value('hotelId', 'HotelId') ?? ''}',
      name: '${value('hotelName', 'HotelName') ?? 'Unnamed hotel'}',
      location: '${value('address', 'Address') ?? value('city', 'City') ?? ''}',
      price: number(value('price', 'Price')),
      currency: '${value('currency', 'Currency') ?? 'GBP'}',
      starRating: integer(value('starRating', 'StarRating')),
      guestRating: number(value('guestRating', 'GuestRating')),
      amenities: amenities is List
          ? amenities.map((item) => '$item').toList(growable: false)
          : const [],
      refundable: value('refundable', 'Refundable') == true,
      thumbnail: value('thumbnail', 'Thumbnail')?.toString(),
    );
  }
}
