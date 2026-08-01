import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/flight_repository.dart';
import 'flight_event.dart';
import 'flight_state.dart';

class FlightSearchBloc extends Bloc<FlightSearchEvent, FlightSearchState> {
  FlightSearchBloc(this._repository) : super(FlightSearchInitial()) {
    on<FlightSearchRequested>(_onSearch);
    on<FlightSearchReset>(_onReset);
  }

  final FlightRepository _repository;

  Future<void> _onSearch(
    FlightSearchRequested event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(FlightSearchLoading());
    try {
      final flights = await _repository.searchFlights(event.criteria);
      emit(FlightSearchLoaded(criteria: event.criteria, flights: flights));
    } catch (e) {
      emit(FlightSearchError(e.toString()));
    }
  }

  Future<void> _onReset(
    FlightSearchReset event,
    Emitter<FlightSearchState> emit,
  ) async {
    emit(FlightSearchInitial());
  }
}
