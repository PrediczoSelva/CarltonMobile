import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/hotel_repository.dart';
import 'hotel_event.dart';
import 'hotel_state.dart';

class HotelSearchBloc extends Bloc<HotelSearchEvent, HotelSearchState> {
  HotelSearchBloc(this._repository) : super(HotelSearchInitial()) {
    on<HotelSearchRequested>(_onSearch);
    on<HotelSearchReset>(_onReset);
  }

  final HotelRepository _repository;

  Future<void> _onSearch(
    HotelSearchRequested event,
    Emitter<HotelSearchState> emit,
  ) async {
    emit(HotelSearchLoading());
    try {
      final hotels = await _repository.searchHotels(event.criteria);
      emit(HotelSearchLoaded(criteria: event.criteria, hotels: hotels));
    } catch (e) {
      emit(HotelSearchError(e.toString()));
    }
  }

  Future<void> _onReset(
    HotelSearchReset event,
    Emitter<HotelSearchState> emit,
  ) async {
    emit(HotelSearchInitial());
  }
}
