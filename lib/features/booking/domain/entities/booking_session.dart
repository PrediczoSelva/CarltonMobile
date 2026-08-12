import '../../../flight/domain/entities/flight.dart';
import '../../../flight/domain/entities/flight_search_criteria.dart';
import 'passenger.dart';

/// Shared session that carries booking data across multiple screens
/// (search results -> passenger details -> summary -> payment -> confirmation).
/// Registered as a singleton in DI so every screen reads the same instance.
class BookingSession {
  FlightSearchCriteria? searchCriteria;
  List<Flight> outboundFlights = [];
  List<Flight> returnFlights = [];
  Flight? selectedOutboundFlight;
  Flight? selectedReturnFlight;
  List<Passenger> passengers = [];
  String? contactEmail;
  String? contactPhone;
  String? contactCountry;
  String? paymentMethod;
  String? paymentMetadataJson;
  String? stripePaymentIntentId;
  double? totalPrice;
  String? currency;
  String? bookingReference;
  String? pnr;
  String? bookingStatus;
  int? bookingId;

  bool get hasPassengerData => passengers.isNotEmpty;

  bool get hasSelectedFlight => selectedOutboundFlight != null;

  double get totalFlightPrice {
    var total = 0.0;
    if (selectedOutboundFlight != null) {
      total += selectedOutboundFlight!.price;
    }
    if (selectedReturnFlight != null) {
      total += selectedReturnFlight!.price;
    }
    return total;
  }

  double get totalPriceWithTaxes => (totalPrice ?? totalFlightPrice) * 1.14;

  void reset() {
    searchCriteria = null;
    outboundFlights = [];
    returnFlights = [];
    selectedOutboundFlight = null;
    selectedReturnFlight = null;
    passengers = [];
    contactEmail = null;
    contactPhone = null;
    contactCountry = null;
    paymentMethod = null;
    paymentMetadataJson = null;
    stripePaymentIntentId = null;
    totalPrice = null;
    currency = null;
    bookingReference = null;
    pnr = null;
    bookingStatus = null;
    bookingId = null;
  }
}
