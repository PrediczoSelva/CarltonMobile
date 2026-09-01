import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../flight/presentation/widgets/flight_search_form.dart';
import '../../../hotels/presentation/screens/hotel_search_form.dart';
import '../../../cars/presentation/screens/car_search_form.dart';
import '../../../flight/presentation/bloc/flight_bloc.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab != null) {
      final index = int.tryParse(tab);
      if (index != null && index >= 0 && index < _tabController.length) {
        _tabController.index = index;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Flights'),
            Tab(text: 'Hotels'),
            Tab(text: 'Cars'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocProvider(
            create: (_) => getIt<FlightSearchBloc>(),
            child: const FlightSearchForm(),
          ),
          const HotelSearchForm(),
          const CarSearchForm(),
        ],
      ),
    );
  }
}
