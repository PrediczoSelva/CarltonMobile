import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = ['Flights', 'Hotels', 'Cars'];

  static const _suggestions = [
    _FlightSuggestion(
      from: 'CMB',
      to: 'DXB',
      city: 'Dubai',
      price: 45000,
      date: '20 Aug',
    ),
    _FlightSuggestion(
      from: 'CMB',
      to: 'LHR',
      city: 'London',
      price: 85000,
      date: '25 Aug',
    ),
    _FlightSuggestion(
      from: 'CMB',
      to: 'SIN',
      city: 'Singapore',
      price: 35000,
      date: '18 Aug',
    ),
    _FlightSuggestion(
      from: 'CMB',
      to: 'MLE',
      city: 'Maldives',
      price: 42000,
      date: '22 Aug',
    ),
  ];

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
                        color: selected ? AppColors.accent : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.textOnAccent : AppColors.textSecondary,
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
      return ListView(
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final flight = _suggestions[index];
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
                        child: Icon(Icons.flight_takeoff, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${flight.from} → ${flight.city} (${flight.to})', style: AppTextStyles.bodyLarge),
                            const SizedBox(height: 2),
                            Text(flight.date, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('LKR ${flight.price.toStringAsFixed(0)}', style: AppTextStyles.price),
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
                            Text(hotel.name, style: AppTextStyles.bodyLarge),
                            const SizedBox(height: 2),
                            Text(hotel.location, style: AppTextStyles.bodySmall),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(hotel.rating.toString(), style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('LKR ${hotel.price.toStringAsFixed(0)}', style: AppTextStyles.price),
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

    return const Center(child: Text('Cars search form goes here'));
  }
}

class _FlightSuggestion {
  const _FlightSuggestion({
    required this.from,
    required this.to,
    required this.city,
    required this.price,
    required this.date,
  });

  final String from;
  final String to;
  final String city;
  final double price;
  final String date;
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
