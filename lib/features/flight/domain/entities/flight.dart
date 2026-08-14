import 'package:flutter/foundation.dart';

class Flight {
  const Flight({
    required this.id,
    required this.airline,
    required this.flightCode,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.stops,
    required this.stopLocations,
    required this.price,
    required this.currency,
    required this.aircraft,
    this.bookingKey,
    this.source = '',
    this.seatsAvailable = 0,
    this.segmentKeys = const [],
    this.providerOfferId,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('[Flight.fromJson] keys=${json.keys.toList()}');
      print('[Flight.fromJson] raw=$json');
    }

    String? _s(dynamic a,
        [dynamic b,
        dynamic c,
        dynamic d,
        dynamic e,
        dynamic f,
        dynamic g,
        dynamic h]) {
      for (final v in [a, b, c, d, e, f, g, h]) {
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    int _i(dynamic a, [dynamic b, dynamic c, dynamic d]) {
      for (final v in [a, b, c, d]) {
        if (v is int) return v;
        if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    num? _n(dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
      for (final v in [a, b, c, d, e]) {
        if (v is num) return v;
        if (v is String) {
          final parsed = num.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    DateTime? _dt(dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
      for (final v in [a, b, c, d, e]) {
        if (v is String && v.isNotEmpty) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final route = json['route'] as Map<String, dynamic>? ??
        json['Route'] as Map<String, dynamic>?;
    final priceObj =
        json['price'] is Map ? json['price'] as Map<String, dynamic> : null;

    return Flight(
      id: _i(json['id'], json['flightId'], json['Id'], json['flightID']),
      airline: _s(json['airline'], json['airlineName'], json['Airline'],
              json['carrier'], json['carrierName']) ??
          '',
      flightCode: _s(json['flightCode'], json['flightNumber'],
              json['FlightCode'], json['flightNo'], json['flightIata']) ??
          '',
      origin: _s(
            json['origin'],
            json['departure'],
            json['originAirport'],
            json['from'],
            json['departureAirport'],
          ) ??
          _s(route?['origin'], route?['originAirport'], route?['from'],
              route?['departureAirport']) ??
          '',
      destination: _s(
            json['destination'],
            json['destinationAirport'],
            json['to'],
            json['arrivalAirport'],
            json['arrivalIata'],
          ) ??
          _s(route?['destination'], route?['destinationAirport'], route?['to'],
              route?['arrivalAirport']) ??
          '',
      departureTime: _dt(
              json['departureTime'],
              json['departure'],
              json['departureDateTime'],
              json['departureAt'],
              json['departsAt']) ??
          _dt(route?['departureTime'], route?['departure']) ??
          DateTime.now(),
      arrivalTime: _dt(json['arrivalTime'], json['arrival'],
              json['arrivalDateTime'], json['arrivalAt'], json['arrivesAt']) ??
          _dt(route?['arrivalTime'], route?['arrival']) ??
          DateTime.now(),
      duration: _s(json['duration'], json['travelTime'], json['Duration'],
              json['journeyTime'], json['flightDuration']) ??
          '',
      stops: _i(json['stops'], json['numberOfStops'], json['Stops'],
          json['stopCount']),
      stopLocations: (json['stopLocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      price: _n(priceObj?['amount'], priceObj?['price'], json['price'],
                  json['basePrice'], json['Price'])
              ?.toDouble() ??
          0,
      currency: _s(json['currency'], json['currencyCode'], json['Currency'],
              priceObj?['currency']) ??
          'GBP',
      aircraft: _s(json['aircraft'], json['Aircraft'], json['airplane'],
              json['equipment'], json['aircraftType']) ??
          '',
      bookingKey: _s(
          json['bookingKey'],
          json['BookingKey'],
          json['atlasRoutingIdentifier'],
          json['AtlasRoutingIdentifier'],
          json['routingIdentifier'],
          json['amadeusOfferToken'],
          json['fareKey'],
          json['FareKey']),
      source: _s(json['source'], json['Source'], json['dataSource'],
              json['DataSource']) ??
          '',
      seatsAvailable: _i(json['seatsAvailable'], json['SeatsAvailable'],
          json['seatsAvailable'], json['SeatsAvailable']),
      segmentKeys: (json['segmentKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      providerOfferId: _s(json['providerOfferId'], json['ProviderOfferId']),
    );
  }

  final int id;
  final String airline;
  final String flightCode;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String duration;
  final int stops;
  final List<String> stopLocations;
  final double price;
  final String currency;
  final String aircraft;
  final String? bookingKey;
  final String source;
  final int seatsAvailable;
  final List<String> segmentKeys;
  final String? providerOfferId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'airline': airline,
        'flightCode': flightCode,
        'origin': origin,
        'destination': destination,
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'duration': duration,
        'stops': stops,
        'stopLocations': stopLocations,
        'price': price,
        'currency': currency,
        'aircraft': aircraft,
        'bookingKey': bookingKey,
        'source': source,
        'seatsAvailable': seatsAvailable,
        'segmentKeys': segmentKeys,
        'providerOfferId': providerOfferId,
      };

  String get stopsText =>
      stops == 0 ? 'Non-stop' : '$stops stop${stops > 1 ? 's' : ''}';

  @override
  String toString() => '$airline $flightCode ($origin → $destination)';
}
