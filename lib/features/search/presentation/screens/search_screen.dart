import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../flight/presentation/widgets/flight_search_form.dart';
import '../../../hotels/presentation/screens/hotel_search_form.dart';
import '../../../cars/presentation/screens/car_search_form.dart';
import '../../../flight/presentation/bloc/flight_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Flights'),
              Tab(text: 'Hotels'),
              Tab(text: 'Cars'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) => getIt<FlightSearchBloc>(),
              child: const FlightSearchForm(),
            ),
            const HotelSearchForm(),
            const CarSearchForm(),
          ],
        ),
      ),
    );
  }
}
