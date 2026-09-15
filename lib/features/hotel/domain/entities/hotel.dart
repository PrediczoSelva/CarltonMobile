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
    this.description,
    this.facilities = const [],
    this.images = const [],
    this.policies,
    this.contact,
    this.checkInTime,
    this.checkOutTime,
    this.roomTypes = const [],
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
  final String? description;
  final List<String> facilities;
  final List<String> images;
  final HotelPolicies? policies;
  final HotelContact? contact;
  final String? checkInTime;
  final String? checkOutTime;
  final List<HotelRoomType> roomTypes;

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
    final images = value('images', 'Images');
    final facilities = value('facilities', 'Facilities');
    final policies = value('policies', 'Policies');
    final contact = value('contact', 'Contact');
    final roomTypes = value('roomTypes', 'RoomTypes');

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
      description: value('description', 'Description')?.toString(),
      facilities: facilities is List
          ? facilities.map((item) => '$item').toList(growable: false)
          : const [],
      images: images is List
          ? images.map((item) => '$item').toList(growable: false)
          : const [],
      policies: policies is Map<String, dynamic>
          ? HotelPolicies.fromJson(policies)
          : null,
      contact: contact is Map<String, dynamic>
          ? HotelContact.fromJson(contact)
          : null,
      checkInTime: value('checkInTime', 'CheckInTime')?.toString(),
      checkOutTime: value('checkOutTime', 'CheckOutTime')?.toString(),
      roomTypes: roomTypes is List
          ? roomTypes
              .whereType<Map<String, dynamic>>()
              .map(HotelRoomType.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class HotelPolicies {
  const HotelPolicies({
    this.checkIn,
    this.checkOut,
    this.cancellation,
    this.children,
    this.pets,
  });

  final String? checkIn;
  final String? checkOut;
  final String? cancellation;
  final String? children;
  final String? pets;

  factory HotelPolicies.fromJson(Map<String, dynamic> json) {
    return HotelPolicies(
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
      cancellation: json['cancellation']?.toString(),
      children: json['children']?.toString(),
      pets: json['pets']?.toString(),
    );
  }
}

class HotelContact {
  const HotelContact({
    this.phone,
    this.email,
    this.address,
  });

  final String? phone;
  final String? email;
  final String? address;

  factory HotelContact.fromJson(Map<String, dynamic> json) {
    return HotelContact(
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class HotelRoomType {
  const HotelRoomType({
    this.code,
    this.name,
    this.description,
    this.maxOccupancy,
    this.bedType,
    this.images = const [],
  });

  final String? code;
  final String? name;
  final String? description;
  final int? maxOccupancy;
  final String? bedType;
  final List<String> images;

  factory HotelRoomType.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    return HotelRoomType(
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      maxOccupancy: json['maxOccupancy'] is int
          ? json['maxOccupancy']
          : int.tryParse('${json['maxOccupancy']}'),
      bedType: json['bedType']?.toString(),
      images: images is List
          ? images.map((item) => '$item').toList(growable: false)
          : const [],
    );
  }
}
