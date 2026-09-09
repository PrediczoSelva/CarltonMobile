import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/repositories/cruise_repository.dart';
import '../../domain/entities/cruise_search_criteria.dart';
import 'cruise_results_screen.dart';

class CruiseSearchTab extends StatefulWidget {
  const CruiseSearchTab({super.key});

  @override
  State<CruiseSearchTab> createState() => _CruiseSearchTabState();
}

class _CruiseSearchTabState extends State<CruiseSearchTab> {
  final _destinationController = TextEditingController();
  final _departurePortController = TextEditingController();
  late final CruiseRepository _repository;

  String _departureMonth = '';
  String _duration = 'all';
  int _guests = 2;
  int _cabins = 1;
  bool _loading = false;

  static const _months = [
    '2026-09',
    '2026-10',
    '2026-11',
    '2026-12',
    '2027-01',
    '2027-02',
    '2027-03',
    '2027-04',
  ];
  static const _durations = ['all', '1-3', '4-7', '8-14', '15+'];

  @override
  void initState() {
    super.initState();
    _repository = getIt<CruiseRepository>();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _departurePortController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final criteria = CruiseSearchCriteria(
        destination: _destinationController.text.trim(),
        departurePort: _departurePortController.text.trim(),
        departureMonth: _departureMonth,
        duration: _duration,
        guests: _guests,
        cabinsCount: _cabins,
      );
      final cruises = await _repository.searchCruises(criteria);
      if (!mounted) return;
      context.push(
        '/cruises/results',
        extra: CruiseSearchResultArgs(criteria: criteria, cruises: cruises),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_boat_outlined,
                    size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Cruise search', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Discover sailings, ports, and cruise packages.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _textField('Destination', _destinationController,
                Icons.explore_outlined, 'Any destination'),
            const SizedBox(height: 16),
            _textField('Departure port', _departurePortController,
                Icons.anchor_outlined, 'Any port / no-fly UK'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: 'Departure month',
                    value: _departureMonth,
                    items: ['', ..._months],
                    labels: {'': 'Any sailing date'},
                    onChanged: (value) =>
                        setState(() => _departureMonth = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: 'Duration',
                    value: _duration,
                    items: _durations,
                    labels: const {
                      'all': 'Any duration',
                      '1-3': '1-3 nights',
                      '4-7': '4-7 nights',
                      '8-14': '8-14 nights',
                      '15+': '15+ nights',
                    },
                    onChanged: (value) => setState(() => _duration = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _stepper('Guests', _guests, 1, 8,
                        (value) => setState(() => _guests = value))),
                const SizedBox(width: 12),
                Expanded(
                    child: _stepper('Cabins', _cabins, 1, 4,
                        (value) => setState(() => _cabins = value))),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Search Cruises',
              isLoading: _loading,
              onPressed: _loading ? null : _search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
      IconData icon, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label, hintText: hint, prefixIcon: Icon(icon)),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) =>
              DropdownMenuItem(value: item, child: Text(labels[item] ?? item)))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Widget _stepper(
      String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove)),
          Text('$value',
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700)),
          IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
