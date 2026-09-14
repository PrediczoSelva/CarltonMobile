import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../../flight/domain/entities/flight_search_criteria.dart';
import '../../../flight/domain/repositories/flight_repository.dart';
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
  late final FlightRepository _flightRepository;
  late final ApiClient _apiClient;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  DateTime? _newDepartureDate;
  List<String> _fromSuggestions = const [];
  List<String> _toSuggestions = const [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  List<Flight> _flights = const [];
  Flight? _selectedFlight;
  Map<String, dynamic>? _quote;
  bool _loading = false;
  bool _quoting = false;
  bool _confirming = false;
  String? _error;

  static const List<String> _defaultPlaces = [
    'Colombo (CMB)',
    'London (LHR)',
    'London Gatwick (LGW)',
    'Dubai (DXB)',
    'Doha (DOH)',
    'Singapore (SIN)',
    'Bangkok (BKK)',
    'Kuala Lumpur (KUL)',
    'Maldives (MLE)',
    'Paris (CDG)',
    'Frankfurt (FRA)',
    'Istanbul (IST)',
    'New York (JFK)',
    'Manchester (MAN)',
    'Edinburgh (EDI)',
    'Birmingham (BHX)',
    'Gatwick (LGW)',
  ];

  @override
  void initState() {
    super.initState();
    _flightRepository = getIt<FlightRepository>();
    _apiClient = getIt<ApiClient>();
    _fromController = TextEditingController(text: widget.booking.flight.origin);
    _toController =
        TextEditingController(text: widget.booking.flight.destination);
    _newDepartureDate = widget.booking.flight.departureTime;
    _fromController.addListener(_onFromInputChanged);
    _toController.addListener(_onToInputChanged);
    _loadPlacesFromFlights();
    _loadPlacesFromFlights();
  }

  @override
  void dispose() {
    _fromController.removeListener(_onFromInputChanged);
    _toController.removeListener(_onToInputChanged);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onFromInputChanged() => _updateSuggestions(isFromField: true);

  void _onToInputChanged() => _updateSuggestions(isFromField: false);

  Future<void> _loadPlacesFromFlights() async {
    try {
      await _flightRepository.getAllFlights();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  List<String> _filterPlaces(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return _defaultPlaces.take(8).toList();

    final matches = <String>[];
    for (final place in _defaultPlaces) {
      final lower = place.toLowerCase();
      if (lower.contains(normalizedQuery)) matches.add(place);
    }
    return matches.take(8).toList();
  }

  void _updateSuggestions({required bool isFromField}) {
    final controller = isFromField ? _fromController : _toController;
    final query = controller.text.trim();
    final matches = query.isEmpty
        ? (isFromField ? _defaultPlaces : _defaultPlaces).take(8).toList()
        : _filterPlaces(query);
    if (!mounted) return;
    setState(() {
      if (isFromField) {
        _fromSuggestions = matches;
        _showFromSuggestions = matches.isNotEmpty;
      } else {
        _toSuggestions = matches;
        _showToSuggestions = matches.isNotEmpty;
      }
    });
  }

  void _selectSuggestion({required bool isFromField, required String place}) {
    final controller = isFromField ? _fromController : _toController;
    controller
      ..text = place
      ..selection = TextSelection.collapsed(offset: place.length);
    setState(() {
      if (isFromField) {
        _showFromSuggestions = false;
      } else {
        _showToSuggestions = false;
      }
    });
  }

  String _cleanFlightCode(String code) {
    return code.split(RegExp(r'\s*→\s*')).first.trim();
  }

  String _formatPrice(double price, String currency) {
    switch (currency.toUpperCase()) {
      case 'GBP':
        return '£${price.toStringAsFixed(0)}';
      case 'USD':
        return '\$${price.toStringAsFixed(0)}';
      case 'EUR':
        return '€${price.toStringAsFixed(0)}';
      default:
        return '$currency ${price.toStringAsFixed(0)}';
    }
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
      final criteria = FlightSearchCriteria(
        origin: _fromController.text.trim(),
        destination: _toController.text.trim(),
        departureDate: _newDepartureDate!,
        passengers: widget.booking.passengers.length > 0
            ? widget.booking.passengers.length
            : 1,
        tripType: 'one-way',
      );
      _flights = await _flightRepository.searchFlights(criteria);

      if (!mounted) return;
      setState(() {
        _flights = _flights
            .where((flight) =>
                flight.id != widget.booking.flight.id ||
                !flight.departureTime
                    .isAtSameMomentAs(widget.booking.flight.departureTime))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          'amadeusNewFlightNumber': flight.flightCode
              .split(RegExp(r'\s*→\s*'))
              .first
              .trim(),
          'amadeusNewDepartureDate': flight.departureTime.toIso8601String(),
        },
      );
      if (mounted)
        setState(() => _quote = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : null);
    } on DioException catch (error) {
      if (mounted) {
        final message = error.response?.data is Map
            ? (error.response?.data as Map)['message']?.toString()
            : null;
        _showMessage(message ?? 'Unable to quote flight exchange.');
      }
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
        'flightNumber': flight.flightCode
            .split(RegExp(r'\s*→\s*'))
            .first
            .trim(),
        'newDepartureTime': flight.departureTime.toIso8601String(),
        'newArrivalTime': flight.arrivalTime.toIso8601String(),
        'reason': 'Customer requested schedule change',
      });
      if (!mounted) return;
      _showMessage('Flight changed successfully.');
      Navigator.pop(context, true);
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map ? (data)['message']?.toString() : null;
      final lowerMessage = (message ?? '').toLowerCase();
      if (lowerMessage.contains('insufficient wallet balance') ||
          lowerMessage.contains('wallet')) {
        _showMessage(message!);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.push(AppRoutes.wallet);
        }
      } else {
        _showMessage(
            message ?? 'Payment or flight change failed. Please try again.');
      }
    } catch (_) {
      if (mounted)
        _showMessage('Payment or flight change failed. Please try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Widget _buildLocationInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> suggestions,
    required bool showSuggestions,
    required bool isFromField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          onChanged: (_) => _updateSuggestions(isFromField: isFromField),
          onTap: () => _updateSuggestions(isFromField: isFromField),
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(place),
                  onTap: () => _selectSuggestion(
                    isFromField: isFromField,
                    place: place,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

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
          _buildLocationInput(
            label: 'From',
            hint: 'City or airport',
            controller: _fromController,
            suggestions: _fromSuggestions,
            showSuggestions: _showFromSuggestions,
            isFromField: true,
          ),
          const SizedBox(height: 12),
          _buildLocationInput(
            label: 'To',
            hint: 'City or airport',
            controller: _toController,
            suggestions: _toSuggestions,
            showSuggestions: _showToSuggestions,
            isFromField: false,
          ),
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
          title: Text('${flight.airline} · ${_cleanFlightCode(flight.flightCode)}'),
          subtitle: Text(
              '${DateFormat('dd MMM, HH:mm').format(flight.departureTime)}  →  ${DateFormat('HH:mm').format(flight.arrivalTime)}\n${flight.origin} → ${flight.destination}'),
          trailing: Text(
              _formatPrice(flight.price, flight.currency),
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
                'New flight: ${_cleanFlightCode(flight.flightCode)} · ${DateFormat('dd MMM, HH:mm').format(flight.departureTime)}'),
            const SizedBox(height: 8),
            if (_quoting)
              const LinearProgressIndicator()
            else
              Text(
                  totalDue > 0
                      ? 'Amount due now: ${_formatPrice(totalDue, _quote?['currency'] as String? ?? widget.booking.currency)}'
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
