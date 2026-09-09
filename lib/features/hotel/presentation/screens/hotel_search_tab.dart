import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/repositories/hotel_repository.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import 'hotel_results_screen.dart';

class HotelSearchTab extends StatefulWidget {
  const HotelSearchTab({super.key});

  @override
  State<HotelSearchTab> createState() => _HotelSearchTabState();
}

class _HotelSearchTabState extends State<HotelSearchTab> {
  final _destinationController = TextEditingController();
  final _defaultPlaces = const [
    'London (LON)',
    'Colombo (CMB)',
    'Dubai (DXB)',
    'Singapore (SIN)',
    'Paris (PAR)',
    'Tokyo (TYO)',
    'New York (NYC)',
  ];

  late final HotelRepository _repository;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 10));
  int _guests = 2;
  int _rooms = 1;
  bool _loading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HotelRepository>();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool checkIn}) async {
    final initial = checkIn ? _checkIn : _checkOut;
    final firstDate = checkIn ? DateTime.now() : _checkIn;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (checkIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  Future<void> _search() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      _showMessage('Please enter a destination.');
      return;
    }
    if (!_checkOut.isAfter(_checkIn)) {
      _showMessage('Check-out must be after check-in.');
      return;
    }

    setState(() => _loading = true);
    try {
      final criteria = HotelSearchCriteria(
        destination: destination,
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _guests,
        children: 0,
        rooms: _rooms,
      );
      final hotels = await _repository.searchHotels(criteria);
      if (!mounted) return;
      context.push(
        '/hotels/results',
        extra: HotelSearchResultArgs(criteria: criteria, hotels: hotels),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final suggestions = _defaultPlaces
        .where((place) => place.toLowerCase().contains(
              _destinationController.text.trim().toLowerCase(),
            ))
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.hotel_outlined,
                    size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Hotel search', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Search live hotel availability for your trip.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildDestinationField(suggestions),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        'Check-in', _checkIn, () => _pickDate(checkIn: true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDateField('Check-out', _checkOut,
                        () => _pickDate(checkIn: false))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Guests',
                    value: _guests,
                    max: _rooms * 4,
                    suffix: 'guest',
                    onChanged: (value) => setState(() => _guests = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Rooms',
                    value: _rooms,
                    max: 5,
                    suffix: 'room',
                    onChanged: (value) {
                      setState(() {
                        _rooms = value;
                        _guests = _guests.clamp(1, value * 4);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Search Hotels',
              isLoading: _loading,
              onPressed: _loading ? null : _search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationField(List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Destination', style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: _destinationController,
          onChanged: (_) => setState(() => _showSuggestions = true),
          onTap: () => setState(() => _showSuggestions = true),
          decoration: const InputDecoration(
            hintText: 'City name or code (e.g. London, LON)',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        if (_showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: suggestions
                  .map(
                    (place) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(place),
                      onTap: () {
                        _destinationController.text = place;
                        setState(() => _showSuggestions = false);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(_formatDate(date)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        max,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text('${index + 1} $suffix${index == 0 ? '' : 's'}'),
        ),
      ),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
