import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../domain/entities/flight_search_criteria.dart';
import '../../presentation/bloc/flight_bloc.dart';
import '../../presentation/bloc/flight_event.dart';
import '../../presentation/bloc/flight_state.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _fromController = TextEditingController(text: 'Colombo (CMB)');
  final _toController = TextEditingController(text: 'London (LHR)');
  DateTime? _departure;
  DateTime? _return;
  int _passengers = 1;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture
          ? now
          : (_return ?? now).add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDeparture) {
          _departure = picked;
        } else {
          _return = picked;
        }
      });
    }
  }

  void _searchFlights() {
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty ||
        _departure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final criteria = FlightSearchCriteria(
      origin: _fromController.text.trim(),
      destination: _toController.text.trim(),
      departureDate: _departure!,
      returnDate: _return,
      passengers: _passengers,
    );

    context.read<FlightSearchBloc>().add(FlightSearchRequested(criteria));
  }

  void _onResultsLoaded(FlightSearchLoaded state) {
    final session = getIt<BookingSession>();
    session.reset();
    session.searchCriteria = state.criteria;
    session.outboundFlights = state.flights;

    if (state.flights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flights found for your search.')),
      );
      return;
    }

    context.push('/flights/results');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search flights')),
      body: BlocListener<FlightSearchBloc, FlightSearchState>(
        listener: (context, state) {
          if (state is FlightSearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is FlightSearchLoaded) {
            _onResultsLoaded(state);
          }
        },
        child: BlocBuilder<FlightSearchBloc, FlightSearchState>(
          builder: (context, state) {
            final isLoading = state is FlightSearchLoading;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        hintText: 'City or airport',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        hintText: 'City or airport',
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _pickDate(isDeparture: true),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Departure'),
                        child: Text(
                          _departure == null
                              ? 'Select date'
                              : '${_departure!.day}/${_departure!.month}/${_departure!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _pickDate(isDeparture: false),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Return'),
                        child: Text(
                          _return == null
                              ? 'Optional'
                              : '${_return!.day}/${_return!.month}/${_return!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Passengers', style: AppTextStyles.bodyLarge),
                        const Spacer(),
                        IconButton(
                          onPressed: _passengers > 1
                              ? () => setState(() => _passengers--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_passengers', style: AppTextStyles.h3),
                        IconButton(
                          onPressed: _passengers < 9
                              ? () => setState(() => _passengers++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Search flights',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _searchFlights,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
