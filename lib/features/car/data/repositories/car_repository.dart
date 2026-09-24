import '../../domain/entities/car_extra_option.dart';
import '../../domain/entities/car_search_criteria.dart';
import '../../domain/entities/car_vehicle.dart';

abstract class CarRepository {
  Future<List<CarVehicle>> searchCars(CarSearchCriteria criteria);
  Future<List<CarExtraOption>> getExtraOptions(String vehicleId);
}
