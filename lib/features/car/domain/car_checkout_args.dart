import 'entities/car_extra_option.dart';
import 'entities/car_search_criteria.dart';
import 'entities/car_vehicle.dart';

/// Carries the in-progress car-hire checkout state between wizard pages
/// (vehicle details -> extras -> guest details -> confirmation), mirroring
/// the web app's `CarHireBookingContext` checkout slice.
class CarCheckoutArgs {
  CarCheckoutArgs({
    required this.car,
    required this.criteria,
    this.selectedExtras = const [],
    this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.licenceNumber,
    this.licenceExpiry,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final CarVehicle car;
  final CarSearchCriteria criteria;
  final List<CarExtraOption> selectedExtras;
  final String? guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String? licenceNumber;
  final String? licenceExpiry;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  int get rentalDays => criteria.rentalDays;

  double get vehicleSubtotal => car.dailyPrice * rentalDays;

  double get extrasSubtotal {
    var total = 0.0;
    for (final extra in selectedExtras) {
      total += extra.totalCost(rentalDays);
    }
    return total;
  }

  double get subtotal => vehicleSubtotal + extrasSubtotal;
  double get taxes => subtotal * 0.2;
  double get total => subtotal + taxes;

  CarCheckoutArgs copyWith({
    CarVehicle? car,
    CarSearchCriteria? criteria,
    List<CarExtraOption>? selectedExtras,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? licenceNumber,
    String? licenceExpiry,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) =>
      CarCheckoutArgs(
        car: car ?? this.car,
        criteria: criteria ?? this.criteria,
        selectedExtras: selectedExtras ?? this.selectedExtras,
        guestName: guestName ?? this.guestName,
        guestEmail: guestEmail ?? this.guestEmail,
        guestPhone: guestPhone ?? this.guestPhone,
        licenceNumber: licenceNumber ?? this.licenceNumber,
        licenceExpiry: licenceExpiry ?? this.licenceExpiry,
        emergencyContactName:
            emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
      );

  static CarCheckoutArgs from(Map<dynamic, dynamic> map) {
    final extra = map['extras'];
    List<CarExtraOption> extras = [];
    if (extra is List) {
      extras = extra
          .whereType<CarExtraOption>()
          .toList(growable: false);
    }
    return CarCheckoutArgs(
      car: map['car'] as CarVehicle,
      criteria: map['criteria'] as CarSearchCriteria,
      selectedExtras: extras,
      guestName: map['guestName'] as String?,
      guestEmail: map['guestEmail'] as String?,
      guestPhone: map['guestPhone'] as String?,
      licenceNumber: map['licenceNumber'] as String?,
      licenceExpiry: map['licenceExpiry'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'car': car,
        'criteria': criteria,
        'extras': selectedExtras,
        'guestName': guestName,
        'guestEmail': guestEmail,
        'guestPhone': guestPhone,
        'licenceNumber': licenceNumber,
        'licenceExpiry': licenceExpiry,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
      };
}
