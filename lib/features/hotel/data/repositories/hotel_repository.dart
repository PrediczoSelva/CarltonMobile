import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';

abstract class HotelRepository {
  Future<List<Hotel>> searchHotels(
    HotelSearchCriteria criteria, {
    int limit = 20,
    int offset = 0,
  });
  Future<Hotel> getHotelDetails(String hotelId);
  Future<List<HotelOffer>> getHotelOffers(
    String hotelId,
    HotelSearchCriteria criteria,
  );
}

class HotelOffer {
  const HotelOffer({
    required this.offerId,
    required this.roomName,
    this.description,
    required this.price,
    required this.taxes,
    required this.currency,
    this.cancellationPolicy,
    required this.refundable,
    this.mealPlan,
    required this.availableQuantity,
    required this.maxOccupancy,
    this.bedType,
    this.amenities = const [],
    this.images = const [],
  });

  final String offerId;
  final String roomName;
  final String? description;
  final double price;
  final double taxes;
  final String currency;
  final String? cancellationPolicy;
  final bool refundable;
  final String? mealPlan;
  final int availableQuantity;
  final int maxOccupancy;
  final String? bedType;
  final List<String> amenities;
  final List<String> images;

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    dynamic value(String camel, String pascal) => json[camel] ?? json[pascal];
    double number(dynamic raw) =>
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    int integer(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

    final amenities = value('amenities', 'Amenities');
    final images = value('images', 'Images');

    return HotelOffer(
      offerId: '${value('offerId', 'OfferId') ?? ''}',
      roomName: '${value('roomName', 'RoomName') ?? ''}',
      description: value('description', 'Description')?.toString(),
      price: number(value('price', 'Price')),
      taxes: number(value('taxes', 'Taxes')),
      currency: '${value('currency', 'Currency') ?? 'GBP'}',
      cancellationPolicy:
          value('cancellationPolicy', 'CancellationPolicy')?.toString(),
      refundable: value('refundable', 'Refundable') == true,
      mealPlan: value('mealPlan', 'MealPlan')?.toString(),
      availableQuantity: integer(value('availableQuantity', 'AvailableQuantity')),
      maxOccupancy: integer(value('maxOccupancy', 'MaxOccupancy')),
      bedType: value('bedType', 'BedType')?.toString(),
      amenities: amenities is List
          ? amenities.map((item) => '$item').toList(growable: false)
          : const [],
      images: images is List
          ? images.map((item) => '$item').toList(growable: false)
          : const [],
    );
  }
}
