import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../../flight/domain/repositories/flight_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  late final FlightRepository _flightRepository;
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

  @override
  void initState() {
    super.initState();
    _flightRepository = getIt<FlightRepository>();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
      _suggestionsError = null;
    });
    try {
      final flights = await _flightRepository.getAllFlights();
      if (mounted) {
        setState(() {
          _suggestedFlights = flights.take(4).toList();
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

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carlton Leisure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
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
              onTap: () => context.push('/flights/search'),
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
                  onPressed: () => context.push('/flights/search'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFlightSuggestions(),
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
              TextButton(onPressed: () {}, child: const Text('See all')),
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
                        child: Icon(Icons.hotel, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hotel.name,
                                style: AppTextStyles.bodyLarge),
                            const SizedBox(height: 2),
                            Text(hotel.location,
                                style: AppTextStyles.bodySmall),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(hotel.rating.toString(),
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GBP ${hotel.price.toStringAsFixed(0)}',
                            style: AppTextStyles.price,
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(64, 32),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
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
            TextButton(onPressed: () {}, child: const Text('See all')),
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
                      child: Icon(Icons.directions_car,
                          color: AppColors.primary),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
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
                  child: Icon(Icons.flight_takeoff,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${flight.origin} → ${flight.destination}',
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${flight.airline} ${flight.flightCode} • ${_formatDate(flight.departureTime)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${flight.currency} ${flight.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price,
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => context.push('/flights/search'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(64, 32),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
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
