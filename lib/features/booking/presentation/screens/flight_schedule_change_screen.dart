import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../domain/entities/booking.dart';

class FlightScheduleChangeScreen extends StatefulWidget {
  const FlightScheduleChangeScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<FlightScheduleChangeScreen> createState() =>
      _FlightScheduleChangeScreenState();
}

class _FlightScheduleChangeScreenState
    extends State<FlightScheduleChangeScreen> {
  late final ApiClient _apiClient;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  DateTime? _newDepartureDate;
  List<Flight> _flights = const [];
  Flight? _selectedFlight;
  Map<String, dynamic>? _quote;
  bool _loading = false;
  bool _quoting = false;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt<ApiClient>();
    _fromController = TextEditingController(text: widget.booking.flight.origin);
    _toController =
        TextEditingController(text: widget.booking.flight.destination);
    _newDepartureDate = widget.booking.flight.departureTime;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  String _airportCode(String value) {
    final match = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(value);
    return match?.group(1)?.toUpperCase() ?? value.trim();
  }

  Future<void> _pickDate() async {
    final minimum = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (_newDepartureDate ?? minimum).isBefore(minimum)
          ? minimum
          : _newDepartureDate!,
      firstDate: minimum,
      lastDate: minimum.add(const Duration(days: 730)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _newDepartureDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _newDepartureDate?.hour ?? 0,
        _newDepartureDate?.minute ?? 0,
      );
      _selectedFlight = null;
      _quote = null;
    });
  }

  Future<void> _searchFlights() async {
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty ||
        _newDepartureDate == null) {
      _showMessage('Enter the route and new departure date.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _selectedFlight = null;
      _quote = null;
    });

    try {
      final response =
          await _apiClient.get<dynamic>('/bookings/available-flights', query: {
        'departure': _airportCode(_fromController.text),
        'destination': _airportCode(_toController.text),
        'departureDateFrom':
            DateFormat('yyyy-MM-dd').format(_newDepartureDate!),
        'departureDateTo': DateFormat('yyyy-MM-dd').format(_newDepartureDate!),
      });
      final data = response.data;
      final values = data is List
          ? data
          : data is Map
              ? data['flights'] ?? data['results'] ?? data['items'] ?? const []
              : const [];
      if (!mounted) return;
      setState(() {
        _flights = values is List
            ? values
                .whereType<Map>()
                .map((item) {
                  return Flight.fromJson(Map<String, dynamic>.from(item));
                })
                .where((flight) =>
                    flight.flightCode != widget.booking.flight.flightCode)
                .toList()
            : const [];
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = (error.response?.data is Map
                ? (error.response?.data as Map)['message']?.toString()
                : null) ??
            'Unable to search alternative flights.';
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Unable to search alternative flights.';
        });
    }
  }

  Future<void> _selectFlight(Flight flight) async {
    setState(() {
      _selectedFlight = flight;
      _quote = null;
      _quoting = true;
    });
    try {
      final response = await _apiClient.post<dynamic>(
        '/bookings/${widget.booking.id}/exchange-quote',
        data: {
          'amadeusNewFlightNumber': flight.flightCode,
          'amadeusNewDepartureDate': flight.departureTime.toIso8601String(),
        },
      );
      if (mounted)
        setState(() => _quote = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : null);
    } catch (_) {
      if (mounted) {
        final difference = flight.price * widget.booking.passengers.length -
            widget.booking.totalPrice;
        setState(() => _quote = {
              'fareDifference': difference,
              'penaltyAmount': 0,
              'totalAmountToPay': difference > 0 ? difference : 0,
              'currency': widget.booking.currency,
            });
      }
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _confirmChange() async {
    final flight = _selectedFlight;
    if (flight == null || _confirming) return;
    setState(() => _confirming = true);
    try {
      final totalDue = (_quote?['totalAmountToPay'] as num?)?.toDouble() ?? 0;
      await _apiClient
          .put<dynamic>('/bookings/${widget.booking.id}/change-flight', data: {
        'newFlightId': flight.id,
        'price': totalDue,
        'departure': flight.origin,
        'destination': flight.destination,
        'flightNumber': flight.flightCode,
        'newDepartureTime': flight.departureTime.toIso8601String(),
        'newArrivalTime': flight.arrivalTime.toIso8601String(),
        'reason': 'Customer requested schedule change',
      });
      if (!mounted) return;
      _showMessage('Flight changed successfully.');
      Navigator.pop(context, true);
    } on DioException catch (error) {
      if (!mounted) return;
      final message = error.response?.data is Map
          ? (error.response?.data as Map)['message']?.toString()
          : null;
      _showMessage(
          message ?? 'Payment or flight change failed. Please try again.');
    } catch (_) {
      if (mounted)
        _showMessage('Payment or flight change failed. Please try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final selected = _selectedFlight;
    final totalDue = (_quote?['totalAmountToPay'] as num?)?.toDouble() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Change flight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Search new flights', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
              'Booking ${widget.booking.pnr.isEmpty ? widget.booking.id : widget.booking.pnr}',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          TextField(
              controller: _fromController,
              decoration: const InputDecoration(
                  labelText: 'From',
                  prefixIcon: Icon(Icons.flight_takeoff_outlined))),
          const SizedBox(height: 12),
          TextField(
              controller: _toController,
              decoration: const InputDecoration(
                  labelText: 'To',
                  prefixIcon: Icon(Icons.flight_land_outlined))),
          const SizedBox(height: 12),
          InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'New departure date',
                      prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                      DateFormat('dd MMM yyyy').format(_newDepartureDate!)))),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _loading ? null : _searchFlights,
              icon: const Icon(Icons.search),
              label: Text(_loading ? 'Searching...' : 'Search new flights')),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error))),
          if (!_loading && _flights.isEmpty && _error == null)
            const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                    'Search for a new date and route to see available flights.')),
          if (_flights.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('${_flights.length} available flights',
                style: AppTextStyles.h4),
            const SizedBox(height: 8),
            ..._flights.map(
                (flight) => _flightCard(flight, selected?.id == flight.id)),
          ],
          if (selected != null && _quote != null) ...[
            const SizedBox(height: 16),
            _quoteCard(selected, totalDue),
          ],
        ],
      ),
    );
  }

  Widget _flightCard(Flight flight, bool selected) => Card(
        color: selected ? AppColors.surfaceVariant : null,
        child: ListTile(
          onTap: () => _selectFlight(flight),
          leading: Icon(selected ? Icons.check_circle : Icons.flight,
              color: AppColors.primary),
          title: Text('${flight.airline} · ${flight.flightCode}'),
          subtitle: Text(
              '${DateFormat('dd MMM, HH:mm').format(flight.departureTime)}  →  ${DateFormat('HH:mm').format(flight.arrivalTime)}\n${flight.origin} → ${flight.destination}'),
          trailing: Text(
              '${flight.currency} ${flight.price.toStringAsFixed(0)}',
              style: AppTextStyles.price),
        ),
      );

  Widget _quoteCard(Flight flight, double totalDue) => Card(
        color: AppColors.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Confirm flight change', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
                'New flight: ${flight.flightCode} · ${DateFormat('dd MMM, HH:mm').format(flight.departureTime)}'),
            const SizedBox(height: 8),
            if (_quoting)
              const LinearProgressIndicator()
            else
              Text(
                  totalDue > 0
                      ? 'Amount due now: ${widget.booking.currency} ${totalDue.toStringAsFixed(2)}'
                      : 'No extra charge for this change.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _quoting || _confirming ? null : _confirmChange,
                    child: Text(_confirming
                        ? 'Processing...'
                        : totalDue > 0
                            ? 'Pay & confirm change'
                            : 'Confirm flight change'))),
          ]),
        ),
      );
}
