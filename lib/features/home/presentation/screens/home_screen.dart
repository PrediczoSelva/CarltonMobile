import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../../flight/domain/entities/flight_search_criteria.dart';
import '../../../flight/domain/repositories/flight_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  late final FlightRepository _flightRepository;
  late final ScrollController _trendingScrollController;
  late final ScrollController _promotionalScrollController;
  List<Flight> _suggestedFlights = [];
  bool _loadingSuggestions = true;
  String? _suggestionsError;

  static const _tabs = ['Flights', 'Hotels', 'Cars'];

  static const _hotelSuggestions = [
    _HotelSuggestion(
      name: 'Shangri-La Colombo',
      location: 'Colombo, Sri Lanka',
      price: 45000,
      rating: 4.8,
    ),
    _HotelSuggestion(
      name: 'Taj Samudra',
      location: 'Colombo, Sri Lanka',
      price: 52000,
      rating: 4.6,
    ),
    _HotelSuggestion(
      name: 'Cinnamon Grand',
      location: 'Colombo, Sri Lanka',
      price: 48000,
      rating: 4.7,
    ),
    _HotelSuggestion(
      name: 'Heritance Kandalama',
      location: 'Dambulla, Sri Lanka',
      price: 38000,
      rating: 4.5,
    ),
  ];

  static const _carSuggestions = [
    _CarSuggestion(
      name: 'Toyota Prius',
      category: 'Sedan',
      price: 8500,
      seats: 5,
    ),
    _CarSuggestion(
      name: 'Honda CR-V',
      category: 'SUV',
      price: 12000,
      seats: 5,
    ),
    _CarSuggestion(
      name: 'Toyota Hiace',
      category: 'Van',
      price: 18000,
      seats: 8,
    ),
    _CarSuggestion(
      name: 'Suzuki Alto',
      category: 'Hatchback',
      price: 5500,
      seats: 4,
    ),
  ];

  static const _trendingDestinations = [
    _TrendingDestination(
      name: 'Belfast',
      subtitle: 'Northern Ireland',
      imageUrl:
          'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=900&q=80',
    ),
    _TrendingDestination(
      name: 'Glasgow',
      subtitle: 'Scotland',
      imageUrl:
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=900&q=80',
    ),
    _TrendingDestination(
      name: 'Northumberland',
      subtitle: 'England',
      imageUrl:
          'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=900&q=80',
    ),
    _TrendingDestination(
      name: 'Edinburgh',
      subtitle: 'Scotland',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
    ),
    _TrendingDestination(
      name: 'Cornwall',
      subtitle: 'England',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  static const _promotionalUpdates = [
    _PromotionalUpdate(
      title: 'Summer Sale',
      subtitle: '20% OFF on all international flights',
      discount: '20% OFF',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      validUntil: 'Valid until Aug 31',
    ),
    _PromotionalUpdate(
      title: 'Early Bird Discount',
      subtitle: 'Save up to £100 on advance bookings',
      discount: 'UPTO £100',
      imageUrl:
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=900&q=80',
      validUntil: 'Valid until Sep 15',
    ),
    _PromotionalUpdate(
      title: 'Family Package',
      subtitle: '15% OFF on group bookings of 4+',
      discount: '15% OFF',
      imageUrl:
          'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=900&q=80',
      validUntil: 'Valid until Oct 01',
    ),
    _PromotionalUpdate(
      title: 'Weekend Getaway',
      subtitle: 'Special rates from £99 per night',
      discount: 'FROM £99',
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f8?auto=format&fit=crop&w=900&q=80',
      validUntil: 'Valid until Sep 30',
    ),
    _PromotionalUpdate(
      title: 'Last Minute Deal',
      subtitle: 'Up to 30% OFF on flights this week',
      discount: '30% OFF',
      imageUrl:
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=900&q=80',
      validUntil: 'Valid until Aug 25',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flightRepository = getIt<FlightRepository>();
    _trendingScrollController = ScrollController();
    _promotionalScrollController = ScrollController();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _trendingScrollController.dispose();
    _promotionalScrollController.dispose();
    super.dispose();
  }

  void _handleTrendingPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    if (!_trendingScrollController.hasClients) {
      return;
    }

    final horizontalDelta =
        event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;
    if (horizontalDelta == 0) {
      return;
    }

    final position = _trendingScrollController.position;
    final targetOffset = (position.pixels + horizontalDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _trendingScrollController.jumpTo(targetOffset.toDouble());
  }

  void _scrollTrendingBy(double delta) {
    if (!_trendingScrollController.hasClients) {
      return;
    }

    final position = _trendingScrollController.position;
    final targetOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _trendingScrollController.animateTo(
      targetOffset.toDouble(),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _handlePromotionalPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    if (!_promotionalScrollController.hasClients) {
      return;
    }

    final horizontalDelta =
        event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;
    if (horizontalDelta == 0) {
      return;
    }

    final position = _promotionalScrollController.position;
    final targetOffset = (position.pixels + horizontalDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _promotionalScrollController.jumpTo(targetOffset.toDouble());
  }

  void _scrollPromotionalBy(double delta) {
    if (!_promotionalScrollController.hasClients) {
      return;
    }

    final position = _promotionalScrollController.position;
    final targetOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _promotionalScrollController.animateTo(
      targetOffset.toDouble(),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
      _suggestionsError = null;
    });
    try {
      final tomorrow = _tomorrow();
      final criteria = FlightSearchCriteria(
        origin: 'Colombo (CMB)',
        destination: 'London (LHR)',
        departureDate: tomorrow,
        passengers: 1,
      );
      final flights = await _flightRepository.searchFlights(criteria);
      if (mounted) {
        setState(() {
          _suggestedFlights =
              flights.where((f) => f.price > 0).take(4).toList();
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
          _suggestionsError = e.toString();
        });
      }
    }
  }

  String _formatTime(DateTime dt) {
    return DateFormat.Hm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carlton Leisure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tabIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.textOnAccent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_tabIndex == 0) {
      return RefreshIndicator(
        onRefresh: _loadSuggestions,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              onTap: () => context.push('/search'),
              decoration: InputDecoration(
                hintText: 'Search flights',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Suggested flights', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFlightSuggestions(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trending destinations', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () {},
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Listener(
                    onPointerSignal: _handleTrendingPointerSignal,
                    child: ScrollConfiguration(
                      behavior: MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: ListView.separated(
                        controller: _trendingScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _trendingDestinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final destination = _trendingDestinations[index];
                          return SizedBox(
                            width: 180,
                            child: _TrendingDestinationCard(
                              destination: destination,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_left,
                        onTap: () => _scrollTrendingBy(-200),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_right,
                        onTap: () => _scrollTrendingBy(200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Promotional updates', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () {},
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Listener(
                    onPointerSignal: _handlePromotionalPointerSignal,
                    child: ScrollConfiguration(
                      behavior: MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: ListView.separated(
                        controller: _promotionalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _promotionalUpdates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final promotion = _promotionalUpdates[index];
                          return SizedBox(
                            width: 180,
                            child: _PromotionalUpdateCard(
                              promotion: promotion,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_left,
                        onTap: () => _scrollPromotionalBy(-200),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_right,
                        onTap: () => _scrollPromotionalBy(200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (_tabIndex == 1) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            onTap: () => context.push('/search?tab=1'),
            decoration: InputDecoration(
              hintText: 'Search hotels',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suggested hotels', style: AppTextStyles.h4),
              TextButton(
                onPressed: () => context.push('/search?tab=1'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hotelSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final hotel = _hotelSuggestions[index];
              return _SuggestedHotelCard(
                hotel: hotel,
                onBook: () => context.push('/search?tab=1'),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
          TextField(
            readOnly: true,
            onTap: () => context.push('/search?tab=2'),
            decoration: InputDecoration(
              hintText: 'Search cars',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suggested cars', style: AppTextStyles.h4),
              TextButton(
                onPressed: () => context.push('/search?tab=2'),
                child: const Text('See all'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _carSuggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final car = _carSuggestions[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.directions_car, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(car.name, style: AppTextStyles.bodyLarge),
                          const SizedBox(height: 2),
                          Text('${car.category} • ${car.seats} seats',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('GBP ${car.price.toStringAsFixed(0)}',
                            style: AppTextStyles.price),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(64, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Book'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFlightSuggestions() {
    if (_loadingSuggestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_suggestionsError != null) {
      return Center(
        child: Text(
          'Could not load suggestions. Pull to refresh to retry.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_suggestedFlights.isEmpty) {
      return Center(
        child: Text(
          'No flights available at the moment.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestedFlights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final flight = _suggestedFlights[index];
        return _SuggestedFlightCard(
          flight: flight,
          formatTime: _formatTime,
          onBook: () => _bookFlight(context, flight),
        );
      },
    );
  }

  void _bookFlight(BuildContext context, Flight flight) {
    final session = getIt<BookingSession>()..reset();
    session.searchCriteria = FlightSearchCriteria(
      origin: '${flight.origin} (${flight.origin})',
      destination: '${flight.destination} (${flight.destination})',
      departureDate: flight.departureTime,
      passengers: 1,
    );
    session.selectedOutboundFlight = flight;
    session.outboundFlights = [flight];
    session.currency = flight.currency;
    context.push('/booking/passenger-details');
  }
}

class _SuggestedHotelCard extends StatefulWidget {
  const _SuggestedHotelCard({
    required this.hotel,
    required this.onBook,
  });

  final _HotelSuggestion hotel;
  final VoidCallback onBook;

  @override
  State<_SuggestedHotelCard> createState() => _SuggestedHotelCardState();
}

class _SuggestedHotelCardState extends State<_SuggestedHotelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppColors.accent.withOpacity(0.45)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_isHovered ? 0.17 : 0.09),
              blurRadius: _isHovered ? 28 : 16,
              offset: Offset(0, _isHovered ? 12 : 7),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.surface,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onBook,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hotel.location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'GBP ${hotel.price.toStringAsFixed(0)}',
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          onPressed: widget.onBook,
                          style: ElevatedButton.styleFrom(
                            elevation: _isHovered ? 1 : 0,
                          ),
                          child: const Text('Book'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedFlightCard extends StatefulWidget {
  const _SuggestedFlightCard({
    required this.flight,
    required this.formatTime,
    required this.onBook,
  });

  final Flight flight;
  final String Function(DateTime) formatTime;
  final VoidCallback onBook;

  @override
  State<_SuggestedFlightCard> createState() => _SuggestedFlightCardState();
}

class _SuggestedFlightCardState extends State<_SuggestedFlightCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppColors.accent.withOpacity(0.45)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_isHovered ? 0.17 : 0.09),
              blurRadius: _isHovered ? 28 : 16,
              offset: Offset(0, _isHovered ? 12 : 7),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.surface,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onBook,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          flight.airline,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          flight.flightCode,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          flight.source.isNotEmpty ? flight.source : 'Catalog',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flight.stopsText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.formatTime(flight.departureTime),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.origin,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(
                                flight.duration.isNotEmpty
                                    ? flight.duration
                                    : flight.stopsText,
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                flight.stopsText,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.formatTime(flight.arrivalTime),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.destination,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${flight.currency} ${flight.price.toStringAsFixed(0)}',
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          onPressed: widget.onBook,
                          style: ElevatedButton.styleFrom(
                            elevation: _isHovered ? 1 : 0,
                          ),
                          child: const Text('Book'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HotelSuggestion {
  const _HotelSuggestion({
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
  });

  final String name;
  final String location;
  final double price;
  final double rating;
}

class _CarSuggestion {
  const _CarSuggestion({
    required this.name,
    required this.category,
    required this.price,
    required this.seats,
  });

  final String name;
  final String category;
  final double price;
  final int seats;
}

class _TrendingDestination {
  const _TrendingDestination({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String imageUrl;
}

class _PromotionalUpdate {
  const _PromotionalUpdate({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.imageUrl,
    required this.validUntil,
  });

  final String title;
  final String subtitle;
  final String discount;
  final String imageUrl;
  final String validUntil;
}

class _TrendingDestinationCard extends StatefulWidget {
  const _TrendingDestinationCard({required this.destination});

  final _TrendingDestination destination;

  @override
  State<_TrendingDestinationCard> createState() =>
      _TrendingDestinationCardState();
}

class _TrendingDestinationCardState extends State<_TrendingDestinationCard> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHighlighted ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          onHighlightChanged: (value) {
            if (_isHighlighted != value) {
              setState(() => _isHighlighted = value);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.destination.name,
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.destination.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionalUpdateCard extends StatefulWidget {
  const _PromotionalUpdateCard({required this.promotion});

  final _PromotionalUpdate promotion;

  @override
  State<_PromotionalUpdateCard> createState() =>
      _PromotionalUpdateCardState();
}

class _PromotionalUpdateCardState extends State<_PromotionalUpdateCard> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHighlighted ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          onHighlightChanged: (value) {
            if (_isHighlighted != value) {
              setState(() => _isHighlighted = value);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.promotion.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.promotion.title,
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.promotion.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.promotion.validUntil,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.promotion.discount,
                    style: AppTextStyles.badge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  const _CarouselArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
