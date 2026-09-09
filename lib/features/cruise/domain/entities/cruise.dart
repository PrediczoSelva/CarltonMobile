class Cruise {
  const Cruise({
    required this.id,
    required this.title,
    required this.cruiseLine,
    required this.shipName,
    required this.shipRating,
    required this.reviewsCount,
    required this.destination,
    required this.departurePort,
    required this.returnPort,
    required this.durationNights,
    required this.departureDates,
    required this.heroImage,
    required this.overview,
    required this.highlights,
    required this.inclusions,
    required this.tags,
    required this.startingPrice,
  });

  final String id;
  final String title;
  final String cruiseLine;
  final String shipName;
  final double shipRating;
  final int reviewsCount;
  final String destination;
  final String departurePort;
  final String returnPort;
  final int durationNights;
  final List<String> departureDates;
  final String heroImage;
  final String overview;
  final List<String> highlights;
  final List<String> inclusions;
  final List<String> tags;
  final double startingPrice;

  factory Cruise.fromJson(Map<String, dynamic> json) {
    dynamic value(String camel, String pascal) => json[camel] ?? json[pascal];
    double number(dynamic raw) =>
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    int integer(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    List<String> strings(dynamic raw) => raw is List
        ? raw.map((item) => '$item').toList(growable: false)
        : const [];

    final dates = value('departureDates', 'DepartureDates');
    return Cruise(
      id: '${value('id', 'Id') ?? ''}',
      title: '${value('title', 'Title') ?? 'Cruise'}',
      cruiseLine: '${value('cruiseLine', 'CruiseLine') ?? ''}',
      shipName: '${value('shipName', 'ShipName') ?? ''}',
      shipRating: number(value('shipRating', 'ShipRating')),
      reviewsCount: integer(value('reviewsCount', 'ReviewsCount')),
      destination: '${value('destination', 'Destination') ?? ''}',
      departurePort: '${value('departurePort', 'DeparturePort') ?? ''}',
      returnPort: '${value('returnPort', 'ReturnPort') ?? ''}',
      durationNights: integer(value('durationNights', 'DurationNights')),
      departureDates: strings(dates),
      heroImage: '${value('heroImage', 'HeroImage') ?? ''}',
      overview: '${value('overview', 'Overview') ?? ''}',
      highlights: strings(value('highlights', 'Highlights')),
      inclusions: strings(value('inclusions', 'Inclusions')),
      tags: strings(value('tags', 'Tags')),
      startingPrice: number(value('startingPrice', 'StartingPrice')),
    );
  }
}
