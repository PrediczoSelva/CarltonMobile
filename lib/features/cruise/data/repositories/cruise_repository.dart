import '../../domain/entities/cruise.dart';
import '../../domain/entities/cruise_search_criteria.dart';

abstract class CruiseRepository {
  Future<List<Cruise>> searchCruises(CruiseSearchCriteria criteria);
}
