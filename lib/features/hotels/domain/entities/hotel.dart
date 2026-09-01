class Hotel {
  const Hotel({
    required this.hotelId,
    required this.hotelName,
    this.address,
    this.latitude,
    this.longitude,
    this.starRating,
    this.amenities = const [],
    this.price,
    this.currency = 'GBP',
    this.refundable = false,
    this.thumbnail,
    this.city,
    this.country,
  });

  final String hotelId;
  final String hotelName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? starRating;
  final List<String> amenities;
  final double? price;
  final String currency;
  final bool refundable;
  final String? thumbnail;
  final String? city;
  final String? country;

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      hotelId: json['hotelId'] as String? ?? '',
      hotelName: json['hotelName'] as String? ?? '',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      starRating: json['starRating'] as int?,
      amenities: json['amenities'] is List
          ? List<String>.from(json['amenities'] as List)
          : const [],
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'GBP',
      refundable: json['refundable'] as bool? ?? false,
      thumbnail: json['thumbnail'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
}
