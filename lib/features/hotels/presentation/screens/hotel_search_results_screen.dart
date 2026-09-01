import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import '../../domain/repositories/hotel_repository.dart';
import '../../../../core/di/injection.dart';

class HotelSearchResultsScreen extends StatefulWidget {
  const HotelSearchResultsScreen({super.key});

  @override
  State<HotelSearchResultsScreen> createState() => _HotelSearchResultsScreenState();
}

class _HotelSearchResultsScreenState extends State<HotelSearchResultsScreen> {
  late HotelSearchCriteria _criteria;
  List<Hotel> _hotels = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final destination = uri.queryParameters['destination'];
    final checkInMs = int.tryParse(uri.queryParameters['checkIn'] ?? '');
    final checkOutMs = int.tryParse(uri.queryParameters['checkOut'] ?? '');
    final adults = int.tryParse(uri.queryParameters['adults'] ?? '1') ?? 1;
    final children = int.tryParse(uri.queryParameters['children'] ?? '0') ?? 0;
    final rooms = int.tryParse(uri.queryParameters['rooms'] ?? '1') ?? 1;

    if (destination != null && checkInMs != null && checkOutMs != null) {
      _criteria = HotelSearchCriteria(
        destination: destination,
        checkIn: DateTime.fromMillisecondsSinceEpoch(checkInMs),
        checkOut: DateTime.fromMillisecondsSinceEpoch(checkOutMs),
        adults: adults,
        children: children,
        rooms: rooms,
      );
      _loadHotels();
    }
  }

  Future<void> _loadHotels() async {
    setState(() => _isLoading = true);
    try {
      final repository = getIt<HotelRepository>();
      final hotels = await repository.searchHotels(_criteria);
      if (mounted) {
        setState(() {
          _hotels = hotels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hotels: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotels in $_criteria.destination'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hotels.isEmpty
              ? const Center(child: Text('No hotels found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = _hotels[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => context.push('/hotels/${hotel.hotelId}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (hotel.thumbnail != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    hotel.thumbnail!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.hotel),
                                      );
                                    },
                                  ),
                                )
                              else
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.hotel),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hotel.hotelName,
                                      style: AppTextStyles.h4,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (hotel.starRating != null)
                                      Row(
                                        children: [
                                          ...List.generate(
                                            hotel.starRating!,
                                            (index) => const Icon(Icons.star, size: 16, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hotel.city ?? hotel.address ?? '',
                                      style: AppTextStyles.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hotel.price != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${hotel.currency} ${hotel.price!.toStringAsFixed(0)}',
                                        style: AppTextStyles.price,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
