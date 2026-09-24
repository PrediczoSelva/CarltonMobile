/// An optional add-on / extra offered by the rental company for a vehicle.
///
/// Mirrors the web `ExtraOption` type (see car-hire/types/carHireTypes.ts) so
/// the mobile and web car-hire flows share the same shape.
class CarExtraOption {
  const CarExtraOption({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerDay,
    required this.priceType,
    required this.icon,
    this.maxQuantity,
    this.category,
    this.productCode,
    this.selectedQuantity = 0,
  });

  final String id;
  final String name;
  final String description;
  final double pricePerDay;

  /// `perDay`, `perRental`, or `oneTime`.
  final String priceType;
  final String icon;
  final int? maxQuantity;
  final String? category;
  final String? productCode;

  /// Quantity currently added to the booking from the UI (0 = not selected).
  final int selectedQuantity;

  CarExtraOption copyWith({int? selectedQuantity}) => CarExtraOption(
        id: id,
        name: name,
        description: description,
        pricePerDay: pricePerDay,
        priceType: priceType,
        icon: icon,
        maxQuantity: maxQuantity,
        category: category,
        productCode: productCode,
        selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      );

  double totalCost(int rentalDays) {
    if (selectedQuantity <= 0) return 0.0;
    final multiplier = isPerDay ? rentalDays : 1;
    return pricePerDay * selectedQuantity * multiplier;
  }

  bool get isPerDay => priceType == 'per_day';
  bool get isIncluded => pricePerDay <= 0;

  factory CarExtraOption.fromJson(Map<String, dynamic> json) {
    double number(dynamic raw) =>
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    int integer(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    dynamic value(String camel, String pascal) => json[camel] ?? json[pascal];
    final maxQty = value('maxQuantity', 'MaxQuantity');
    return CarExtraOption(
      id: '${value('id', 'Id') ?? ''}',
      name: '${value('name', 'Name') ?? 'Add-on'}',
      description: '${value('description', 'Description') ?? ''}',
      pricePerDay: number(value('pricePerDay', 'PricePerDay')),
      priceType: '${value('priceType', 'PriceType') ?? 'per_rental'}',
      icon: '${value('icon', 'Icon') ?? ''}',
      maxQuantity: maxQty == null
          ? null
          : integer(maxQty) > 0
              ? integer(maxQty)
              : null,
      category: value('category', 'Category')?.toString(),
      productCode: value('productCode', 'ProductCode')?.toString(),
    );
  }
}
