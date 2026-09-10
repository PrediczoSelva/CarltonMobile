class CarVehicle {
  const CarVehicle({
    required this.id,
    required this.name,
    required this.category,
    required this.images,
    required this.seats,
    required this.doors,
    required this.transmission,
    required this.fuelType,
    required this.airConditioning,
    required this.unlimitedMileage,
    required this.freeCancellation,
    required this.dailyPrice,
    required this.rating,
    required this.reviewCount,
    required this.companyName,
    required this.mileagePolicy,
    required this.includedFeatures,
  });

  final String id;
  final String name;
  final String category;
  final List<String> images;
  final int seats;
  final int doors;
  final String transmission;
  final String fuelType;
  final bool airConditioning;
  final bool unlimitedMileage;
  final bool freeCancellation;
  final double dailyPrice;
  final double rating;
  final int reviewCount;
  final String companyName;
  final String mileagePolicy;
  final List<String> includedFeatures;

  factory CarVehicle.fromJson(Map<String, dynamic> json) {
    dynamic value(String camel, String pascal) => json[camel] ?? json[pascal];
    double number(dynamic raw) =>
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    int integer(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    final specs = value('specs', 'Specs');
    final specsMap =
        specs is Map ? Map<String, dynamic>.from(specs) : <String, dynamic>{};
    final images = value('images', 'Images');
    final features = value('includedFeatures', 'IncludedFeatures');
    return CarVehicle(
      id: '${value('id', 'Id') ?? ''}',
      name: '${value('name', 'Name') ?? 'Car'}',
      category: '${value('category', 'Category') ?? ''}',
      images:
          images is List ? images.map((item) => '$item').toList() : const [],
      seats: integer(specsMap['seats'] ?? specsMap['Seats']),
      doors: integer(specsMap['doors'] ?? specsMap['Doors']),
      transmission:
          '${specsMap['transmission'] ?? specsMap['Transmission'] ?? ''}',
      fuelType: '${specsMap['fuelType'] ?? specsMap['FuelType'] ?? ''}',
      airConditioning: specsMap['airConditioning'] == true ||
          specsMap['AirConditioning'] == true,
      unlimitedMileage: specsMap['unlimitedMileage'] == true ||
          specsMap['UnlimitedMileage'] == true,
      freeCancellation: specsMap['freeCancellation'] == true ||
          specsMap['FreeCancellation'] == true,
      dailyPrice: number(value('dailyPrice', 'DailyPrice')),
      rating: number(value('rating', 'Rating')),
      reviewCount: integer(value('reviewCount', 'ReviewCount')),
      companyName:
          '${value('companyName', 'CompanyName') ?? value('companyId', 'CompanyId') ?? ''}',
      mileagePolicy: '${value('mileagePolicy', 'MileagePolicy') ?? ''}',
      includedFeatures: features is List
          ? features.map((item) => '$item').toList()
          : const [],
    );
  }
}
