import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc(this._repository) : super(BookingInitial()) {
    on<CreateBookingRequested>(_onCreate);
    on<CreateAtlasBookingRequested>(_onCreateAtlas);
    on<CreateAmadeusBookingRequested>(_onCreateAmadeus);
    on<CreateTravelportBookingRequested>(_onCreateTravelport);
    on<GetUserBookingsRequested>(_onGetUserBookings);
    on<CancelBookingRequested>(_onCancelBooking);
  }

  final BookingRepository _repository;

  Future<void> _onCreate(
    CreateBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final booking = await _repository.createBooking(
        flightId: event.flightId,
        passengers: event.passengers,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        paymentMethod: event.paymentMethod,
        paymentMetadataJson: event.paymentMetadataJson,
      );
      emit(BookingSuccess(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCreateAtlas(
    CreateAtlasBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final booking = await _repository.createAtlasBooking(
        routingIdentifier: event.routingIdentifier,
        passengers: event.passengers,
        contactName: event.contactName,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        bookingClass: event.bookingClass,
        quotedTotal: event.quotedTotal,
        flightSnapshotJson: event.flightSnapshotJson,
        stripePaymentIntentId: event.stripePaymentIntentId,
        isGuest: event.isGuest,
      );
      emit(BookingSuccess(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCreateAmadeus(
    CreateAmadeusBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final booking = await _repository.createAmadeusBooking(
        amadeusOfferToken: event.amadeusOfferToken,
        verifyId: event.verifyId,
        stripePaymentIntentId: event.stripePaymentIntentId,
        baseFareTotal: event.baseFareTotal,
        passengers: event.passengers,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        bookingClass: event.bookingClass,
        quotedTotal: event.quotedTotal,
        flightSnapshotJson: event.flightSnapshotJson,
        isGuest: event.isGuest,
      );
      emit(BookingSuccess(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCreateTravelport(
    CreateTravelportBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final booking = await _repository.createTravelportBooking(
        fareKey: event.fareKey,
        segmentKeys: event.segmentKeys,
        passengers: event.passengers,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        bookingClass: event.bookingClass,
        quotedTotal: event.quotedTotal,
        providerBaseFare: event.providerBaseFare,
        flightSnapshotJson: event.flightSnapshotJson,
        stripePaymentIntentId: event.stripePaymentIntentId,
        isGuest: event.isGuest,
      );
      emit(BookingSuccess(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onGetUserBookings(
    GetUserBookingsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final bookings = await _repository.getUserBookings();
      emit(BookingsListLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      await _repository.cancelBooking(event.bookingId);
      emit(BookingCancelled(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
