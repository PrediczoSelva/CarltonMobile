import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import '../../presentation/bloc/hotel_bloc.dart';
import '../../presentation/bloc/hotel_event.dart';
import '../../presentation/bloc/hotel_state.dart';

class HotelSearchForm extends StatefulWidget {
  const HotelSearchForm({super.key});

  @override
  State<HotelSearchForm> createState() => _HotelSearchFormState();
}

class _HotelSearchFormState extends State<HotelSearchForm> {
  final _destinationController = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _checkIn = picked);
    }
  }

  Future<void> _pickCheckOut() async {
    final now = DateTime.now();
    final initial = _checkOut ?? (_checkIn ?? now).add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _checkIn ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _checkOut = picked);
    }
  }

  void _searchHotels() {
    if (_destinationController.text.trim().isEmpty || _checkIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final criteria = HotelSearchCriteria(
      destination: _destinationController.text.trim(),
      checkIn: _checkIn!,
      checkOut: _checkOut ?? _checkIn!.add(const Duration(days: 1)),
      adults: _adults,
      children: _children,
      rooms: _rooms,
    );

    context.read<HotelSearchBloc>().add(HotelSearchRequested(criteria));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HotelSearchBloc, HotelSearchState>(
      listener: (context, state) {
        if (state is HotelSearchLoaded) {
          final encoded = Uri.encodeComponent(state.criteria.destination);
          context.push('/hotels/results?destination=$encoded&checkIn=${state.criteria.checkIn.millisecondsSinceEpoch}&checkOut=${state.criteria.checkOut.millisecondsSinceEpoch}&adults=${state.criteria.adults}&children=${state.criteria.children}&rooms=${state.criteria.rooms}');
        } else if (state is HotelSearchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<HotelSearchBloc, HotelSearchState>(
        builder: (context, state) {
          final isLoading = state is HotelSearchLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: 'City or hotel name',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickCheckIn,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Check-in'),
                    child: Text(
                      _checkIn == null
                          ? 'Select date'
                          : '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickCheckOut,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Check-out'),
                    child: Text(
                      _checkOut == null
                          ? 'Select date'
                          : '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Rooms', style: AppTextStyles.bodyLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _rooms > 1
                          ? () => setState(() => _rooms--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_rooms', style: AppTextStyles.h3),
                    IconButton(
                      onPressed: () => setState(() => _rooms++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Adults', style: AppTextStyles.bodyLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _adults > 1
                          ? () => setState(() => _adults--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_adults', style: AppTextStyles.h3),
                    IconButton(
                      onPressed: _adults < 10
                          ? () => setState(() => _adults++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Children', style: AppTextStyles.bodyLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _children > 0
                          ? () => setState(() => _children--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_children', style: AppTextStyles.h3),
                    IconButton(
                      onPressed: _children < 10
                          ? () => setState(() => _children++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Search hotels',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _searchHotels,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
