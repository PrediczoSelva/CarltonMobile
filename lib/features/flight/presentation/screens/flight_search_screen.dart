import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../presentation/bloc/flight_bloc.dart';
import '../../presentation/bloc/flight_state.dart';
import '../widgets/flight_search_form.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
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
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    FlightSearchForm(),
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
