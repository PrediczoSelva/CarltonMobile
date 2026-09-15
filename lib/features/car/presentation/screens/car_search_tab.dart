import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/repositories/car_repository.dart';
import '../../domain/entities/car_search_criteria.dart';
import 'car_results_screen.dart';

class CarSearchTab extends StatefulWidget {
  const CarSearchTab({super.key});
  @override
  State<CarSearchTab> createState() => _CarSearchTabState();
}

class _CarSearchTabState extends State<CarSearchTab> {
  final _pickup = TextEditingController(text: 'London Heathrow (LHR)');
  final _dropoff = TextEditingController(text: 'London Heathrow (LHR)');
  final _promo = TextEditingController();
  late final CarRepository _repository;
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 7));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 10));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _returnTime = const TimeOfDay(hour: 10, minute: 0);
  int _driverAge = 30;
  bool _sameDropoff = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repository = getIt<CarRepository>();
  }

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _promo.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool pickup) async {
    final minimum = pickup ? DateTime.now() : _pickupDate;
    final picked = await showDatePicker(
        context: context,
        initialDate: pickup ? _pickupDate : _returnDate,
        firstDate: minimum,
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (!mounted || picked == null) return;
    setState(() {
      if (pickup) {
        _pickupDate = picked;
        if (!_returnDate.isAfter(picked))
          _returnDate = picked.add(const Duration(days: 1));
      } else {
        _returnDate = picked;
      }
    });
  }

  Future<void> _pickTime(bool pickup) async {
    final picked = await showTimePicker(
        context: context, initialTime: pickup ? _pickupTime : _returnTime);
    if (!mounted || picked == null) return;
    setState(() {
      if (pickup)
        _pickupTime = picked;
      else
        _returnTime = picked;
    });
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _time(TimeOfDay t) =>
      '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';

  Future<void> _search() async {
    if (_pickup.text.trim().isEmpty ||
        (!_sameDropoff && _dropoff.text.trim().isEmpty) ||
        !_returnDate.isAfter(_pickupDate) ||
        _driverAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please check the pickup, return, and driver details.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final criteria = CarSearchCriteria(
        pickupLocation: _pickup.text.trim(),
        dropoffLocation:
            _sameDropoff ? _pickup.text.trim() : _dropoff.text.trim(),
        sameDropoff: _sameDropoff,
        pickupDate: _pickupDate,
        returnDate: _returnDate,
        pickupTime:
            '${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}',
        returnTime:
            '${_returnTime.hour.toString().padLeft(2, '0')}:${_returnTime.minute.toString().padLeft(2, '0')}',
        driverAge: _driverAge,
        promoCode: _promo.text,
      );
      final cars = await _repository.searchCars(criteria);
      if (!mounted) return;
      context.push('/cars/results',
          extra: CarSearchResultArgs(criteria: criteria, cars: cars));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))));
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
                  Row(children: [
                    const Icon(Icons.directions_car_outlined,
                        size: 32, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Car hire search', style: AppTextStyles.h3)
                  ]),
                  const SizedBox(height: 8),
                  Text('Find a rental car for your journey.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _field(
                      'Pickup location', _pickup, Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field(
                            'Drop-off location', _dropoff, Icons.flag_outlined,
                            enabled: !_sameDropoff)),
                    const SizedBox(width: 8),
                    Column(children: [
                      const Text('Same'),
                      Checkbox(
                          value: _sameDropoff,
                          onChanged: (value) => setState(() {
                                _sameDropoff = value ?? true;
                                if (_sameDropoff) _dropoff.text = _pickup.text;
                              }))
                    ])
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _dateField(
                            'Pickup date', _pickupDate, () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _timeField(
                            'Pickup time', _pickupTime, () => _pickTime(true)))
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _dateField('Return date', _returnDate,
                            () => _pickDate(false))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _timeField(
                            'Return time', _returnTime, () => _pickTime(false)))
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<int>(
                            initialValue: _driverAge,
                            decoration:
                                const InputDecoration(labelText: 'Driver age'),
                            items: List.generate(
                                82,
                                (i) => DropdownMenuItem(
                                    value: i + 18,
                                    child: Text('${i + 18} years'))),
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _driverAge = value);
                            })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(
                            'Promo code', _promo, Icons.local_offer_outlined))
                  ]),
                  const SizedBox(height: 24),
                  PrimaryButton(
                      label: 'Search Cars',
                      isLoading: _loading,
                      onPressed: _loading ? null : _search),
                ])));
  }

  Widget _field(String label, TextEditingController controller, IconData icon,
          {bool enabled = true}) =>
      TextField(
          controller: controller,
          enabled: enabled,
          onChanged: (_) {
            if (_sameDropoff && controller == _pickup)
              _dropoff.text = controller.text;
          },
          decoration:
              InputDecoration(labelText: label, prefixIcon: Icon(icon)));
  Widget _dateField(String label, DateTime value, VoidCallback tap) => InkWell(
      onTap: tap,
      child: InputDecorator(
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today_outlined)),
          child: Text(_date(value))));
  Widget _timeField(String label, TimeOfDay value, VoidCallback tap) => InkWell(
      onTap: tap,
      child: InputDecorator(
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.schedule_outlined)),
          child: Text(_time(value))));
}
