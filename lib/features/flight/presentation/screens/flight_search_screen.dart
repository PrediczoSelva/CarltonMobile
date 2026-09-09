import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/domain/entities/passenger.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_search_criteria.dart';
import '../../domain/repositories/flight_repository.dart';
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
  final _fromFocusNode = FocusNode();
  final _toFocusNode = FocusNode();

  static const List<String> _defaultPlaces = [
    'Colombo (CMB)',
    'London (LHR)',
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
  ];

  late final FlightRepository _flightRepository;
  List<String> _allPlaces = List<String>.from(_defaultPlaces);
  List<String> _fromSuggestions = const [];
  List<String> _toSuggestions = const [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;

  DateTime? _departure;
  DateTime? _return;
  String _cabinClass = 'Economy';

  static const List<String> _cabinClassOptions = [
    'Economy',
    'Premium Economy',
    'Business',
    'First',
  ];

  static const String _addNewTravellerValue = '__add_new__';

  List<Map<String, dynamic>> _savedTravellers = [];
  Map<String, dynamic>? _loggedInTraveller;
  final List<String?> _passengerSelections = ['-1'];
  bool _passengersExpanded = false;

  late final ApiClient _apiClient;
  late final BookingSession _session;

  @override
  void initState() {
    super.initState();
    _flightRepository = getIt<FlightRepository>();
    _apiClient = getIt<ApiClient>();
    _session = getIt<BookingSession>();
    _fromController.addListener(_onFromInputChanged);
    _toController.addListener(_onToInputChanged);
    _fromFocusNode.addListener(() {
      if (_fromFocusNode.hasFocus) {
        _updateSuggestions(isFromField: true);
      } else if (_showFromSuggestions) {
        setState(() => _showFromSuggestions = false);
      }
    });

    _toFocusNode.addListener(() {
      if (_toFocusNode.hasFocus) {
        _updateSuggestions(isFromField: false);
      } else if (_showToSuggestions) {
        setState(() => _showToSuggestions = false);
      }
    });

    _loadPlacesFromFlights();
    _loadSavedTravellers();
  }

  @override
  void dispose() {
    _fromController.removeListener(_onFromInputChanged);
    _toController.removeListener(_onToInputChanged);
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  void _onFromInputChanged() => _updateSuggestions(isFromField: true);

  void _onToInputChanged() => _updateSuggestions(isFromField: false);

  Future<void> _loadPlacesFromFlights() async {
    try {
      final flights = await _flightRepository.getAllFlights();
      final uniquePlaces = LinkedHashSet<String>.from(_defaultPlaces)
        ..addAll(_extractPlacesFromFlights(flights));

      if (!mounted) {
        return;
      }

      setState(() {
        _allPlaces = uniquePlaces.toList(growable: false);
      });

      _updateSuggestions(isFromField: true);
      _updateSuggestions(isFromField: false);
    } catch (_) {
      // Keep default places if remote place extraction fails.
    }
  }

  List<String> _extractPlacesFromFlights(List<Flight> flights) {
    final places = <String>[];
    for (final flight in flights) {
      final origin = _normalizePlaceValue(flight.origin);
      final destination = _normalizePlaceValue(flight.destination);
      if (origin != null) {
        places.add(origin);
      }
      if (destination != null) {
        places.add(destination);
      }
    }
    return places;
  }

  String? _normalizePlaceValue(String? value) {
    if (value == null) {
      return null;
    }

    final compact = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (compact.isEmpty) {
      return null;
    }

    if (RegExp(r'^[A-Za-z]{3}$').hasMatch(compact)) {
      return compact.toUpperCase();
    }

    return compact.replaceAllMapped(
      RegExp(r'\(([A-Za-z]{3})\)'),
      (match) => '(${match.group(1)!.toUpperCase()})',
    );
  }

  void _updateSuggestions({required bool isFromField}) {
    final controller = isFromField ? _fromController : _toController;
    final focusNode = isFromField ? _fromFocusNode : _toFocusNode;
    final query = controller.text.trim();

    final matches = _filterPlaces(query);
    if (!mounted) {
      return;
    }

    setState(() {
      if (isFromField) {
        _fromSuggestions = matches;
        _showFromSuggestions = focusNode.hasFocus && matches.isNotEmpty;
      } else {
        _toSuggestions = matches;
        _showToSuggestions = focusNode.hasFocus && matches.isNotEmpty;
      }
    });
  }

  List<String> _filterPlaces(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    final places = _allPlaces;

    if (normalizedQuery.isEmpty) {
      return places.take(8).toList(growable: false);
    }

    final startsWithMatches = <String>[];
    final containsMatches = <String>[];

    for (final place in places) {
      final normalizedPlace = place.toLowerCase();
      final airportCode = _extractAirportCode(place).toLowerCase();
      final startsWithWord = normalizedPlace
          .split(RegExp(r'[\s()\-/]+'))
          .any((part) => part.startsWith(normalizedQuery));

      if (normalizedPlace.startsWith(normalizedQuery) ||
          airportCode.startsWith(normalizedQuery) ||
          startsWithWord) {
        startsWithMatches.add(place);
      } else if (normalizedPlace.contains(normalizedQuery) ||
          airportCode.contains(normalizedQuery)) {
        containsMatches.add(place);
      }
    }

    return [...startsWithMatches, ...containsMatches]
        .take(8)
        .toList(growable: false);
  }

  String _extractAirportCode(String place) {
    final match = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(place);
    if (match != null) {
      return match.group(1) ?? '';
    }

    if (RegExp(r'^[A-Za-z]{3}$').hasMatch(place)) {
      return place;
    }

    return '';
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

    if (isFromField) {
      _toFocusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildLocationInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> suggestions,
    required bool showSuggestions,
    required bool isFromField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction:
              isFromField ? TextInputAction.next : TextInputAction.done,
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

  Future<void> _pickDate({required bool isDeparture}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isDeparture ? now : (_return ?? now).add(const Duration(days: 7)),
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

  Future<void> _loadSavedTravellers() async {
    // Load the logged-in user's personal details first
    try {
      final response = await _apiClient.get<dynamic>('/profile/personal');
      if (response.data != null && response.data is Map) {
        _loggedInTraveller = (response.data as Map<String, dynamic>)
          ..['id'] = -1;
      }
    } catch (_) {
      // Fallback: use cached auth user from secure storage
      try {
        final user = await getIt<AuthRepository>().getCurrentUser();
        _loggedInTraveller = {
          'id': -1,
          'firstName': '',
          'lastName': '',
          'name': user.name,
        };
      } catch (_) {}
    }

    // Load saved travelers (excluding the logged-in user)
    try {
      final response = await _apiClient.get<dynamic>('/profile/travellers');
      if (response.data != null && response.data is List) {
        _savedTravellers = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .where((t) => (t['id'] != null && t['id'] != -1))
            .toList();
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _travellerName(Map<String, dynamic> t) {
    final title = t['title'] as String? ?? '';
    final fn = t['firstName'] as String? ?? '';
    final ln = t['lastName'] as String? ?? '';
    final parts = <String>[
      if (title.isNotEmpty) title,
      if (fn.isNotEmpty) fn,
      if (ln.isNotEmpty) ln,
    ];
    final name = parts.join(' ').trim();
    if (name.isNotEmpty) return name;

    final fallbackName = t['name'] as String? ?? '';
    if (fallbackName.isNotEmpty) return fallbackName;

    final username = t['username'] as String? ?? '';
    return username.isNotEmpty ? username : 'Traveller';
  }

  List<DropdownMenuItem<String>> _buildTravellerDropdownItems() {
    return [
      if (_loggedInTraveller != null)
        DropdownMenuItem<String>(
          value: '-1',
          child: Text(_travellerName(_loggedInTraveller!)),
        ),
      ..._savedTravellers.map((t) => DropdownMenuItem<String>(
            value: (t['id'] ?? 0).toString(),
            child: Text(_travellerName(t)),
          )),
      const DropdownMenuItem(
        value: _addNewTravellerValue,
        child: Text('Add New Traveller'),
      ),
    ];
  }

  List<Widget> _buildPassengerSlots() {
    return _passengerSelections.asMap().entries.map((entry) {
      final index = entry.key;
      final selectedId = entry.value;
      final isLast = index == _passengerSelections.length - 1;

      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  hint: const Text('Select traveller'),
                  items: _buildTravellerDropdownItems(),
                  onChanged: (value) {
                    if (value == _addNewTravellerValue) {
                      setState(() => _passengerSelections[index] = null);
                      _showAddTravellerSheet();
                    } else if (value != null) {
                      setState(() => _passengerSelections[index] = value);
                    }
                  },
                  isExpanded: true,
                ),
              ),
            ),
            if (_passengerSelections.length > 1) const SizedBox(width: 8),
            if (_passengerSelections.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _passengerSelections.removeAt(index);
                  });
                },
              ),
          ],
        ),
      );
    }).toList();
  }

  void _showAddTravellerSheet() {
    final controller = _NewTravellerController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Add new traveller', style: AppTextStyles.h4),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the traveller details below and save them for future bookings.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Relationship', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: controller.relationship.text.isEmpty
                      ? null
                      : controller.relationship.text,
                  decoration: const InputDecoration(
                    labelText: 'Select relationship',
                  ),
                  items: const [
                    'Spouse',
                    'Child',
                    'Parent',
                    'Sibling',
                    'Friend',
                    'Colleague',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    controller.relationship.text = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                Text('Passenger Type', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: controller.passengerType.text.isEmpty
                      ? null
                      : controller.passengerType.text,
                  decoration: const InputDecoration(
                    labelText: 'Select type',
                  ),
                  items: const [
                    'Adult',
                    'Child',
                    'Infant',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    controller.passengerType.text = value ?? 'Adult';
                  },
                ),
                const SizedBox(height: 16),
                Text('Personal Information', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.dateOfBirth,
                  readOnly: true,
                  onTap: () {
                    final type = switch (controller.passengerType.text) {
                      'Child' => Passenger.childType,
                      'Infant' => Passenger.infantType,
                      _ => Passenger.adultType,
                    };
                    _pickTravellerDate(
                      context: sheetContext,
                      controller: controller.dateOfBirth,
                      passengerType: type,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.nationality,
                  decoration: const InputDecoration(labelText: 'Nationality'),
                ),
                const SizedBox(height: 16),
                Text('Passport Details', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.passportNumber,
                  decoration:
                      const InputDecoration(labelText: 'Passport Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.issueNumber,
                  decoration: const InputDecoration(labelText: 'Issue Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.passportExpiryDate,
                  readOnly: true,
                  onTap: () => _pickTravellerDate(
                    context: sheetContext,
                    controller: controller.passportExpiryDate,
                    isExpiryDate: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Optional Details', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.frequencyFlyerNo,
                  decoration:
                      const InputDecoration(labelText: 'Frequency Flyer No'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.knownTravellerNo,
                  decoration:
                      const InputDecoration(labelText: 'Known Traveller No'),
                ),
                const SizedBox(height: 16),
                Text('Special Requirement', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.specialRequirement,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Special Requirement',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final firstName = controller.firstName.text.trim();
                          final lastName = controller.lastName.text.trim();
                          if (firstName.isEmpty && lastName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a traveller name'),
                              ),
                            );
                            return;
                          }

                          final dobText = controller.dateOfBirth.text.trim();
                          final expiryText =
                              controller.passportExpiryDate.text.trim();
                          final passportNumber =
                              controller.passportNumber.text.trim();
                          final passengerTypeText =
                              controller.passengerType.text.trim();

                          if (dobText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter date of birth'),
                              ),
                            );
                            return;
                          }

                          final dob = DateTime.tryParse(dobText);
                          if (dob == null || dob.isAfter(DateTime.now())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid date of birth'),
                              ),
                            );
                            return;
                          }

                          final travelDate =
                              _session.searchCriteria?.departureDate ??
                                  DateTime.now();
                          final age = travelDate.difference(dob).inDays ~/ 365;
                          final selectedType = switch (passengerTypeText) {
                            'Child' => Passenger.childType,
                            'Infant' => Passenger.infantType,
                            _ => Passenger.adultType,
                          };

                          if (selectedType == Passenger.infantType &&
                              age >= 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Infant must be under 2 years old on travel date (current age: $age)',
                                ),
                              ),
                            );
                            return;
                          }

                          if (selectedType == Passenger.childType &&
                              (age < 2 || age > 17)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Child must be between 2 and 17 years old on travel date (current age: $age)',
                                ),
                              ),
                            );
                            return;
                          }

                          if (selectedType == Passenger.adultType && age < 18) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Adult must be 18 years or older on travel date (current age: $age)',
                                ),
                              ),
                            );
                            return;
                          }

                          if (passportNumber.isNotEmpty &&
                              expiryText.isNotEmpty) {
                            final expiry = DateTime.tryParse(expiryText);
                            if (expiry == null ||
                                expiry.isBefore(DateTime.now())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Passport expiry date must be a future date',
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          final id =
                              DateTime.now().millisecondsSinceEpoch.toString();
                          setState(() {
                            _savedTravellers.add({
                              'id': int.parse(id),
                              'title':
                                  controller.relationship.text.trim().isNotEmpty
                                      ? controller.relationship.text.trim()
                                      : 'Add New Traveler',
                              'passengerType': selectedType,
                              'firstName': firstName,
                              'lastName': lastName,
                              'dateOfBirth': dobText,
                              'passportNumber': passportNumber,
                              'issueNumber': controller.issueNumber.text.trim(),
                              'passportExpiryDate': expiryText,
                              'nationality': controller.nationality.text.trim(),
                              'frequencyFlyerNo':
                                  controller.frequencyFlyerNo.text.trim(),
                              'knownTravellerNo':
                                  controller.knownTravellerNo.text.trim(),
                              'specialRequirement':
                                  controller.specialRequirement.text.trim(),
                              'passportCountry':
                                  controller.nationality.text.trim(),
                            });
                            final nullIndex = _passengerSelections
                                .indexWhere((s) => s == null);
                            if (nullIndex != -1) {
                              _passengerSelections[nullIndex] = id;
                            }
                          });
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Traveller'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTravellerDate({
    required BuildContext context,
    required TextEditingController controller,
    int? passengerType,
    bool isExpiryDate = false,
  }) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 80)),
    );
    if (picked != null) {
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      controller.text = dateStr;

      if (isExpiryDate) {
        if (picked.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expiry date must be a future date'),
            ),
          );
        }
      }

      if (passengerType != null && !isExpiryDate) {
        final travelDate =
            _session.searchCriteria?.departureDate ?? DateTime.now();
        final age = travelDate.difference(picked).inDays ~/ 365;
        if (passengerType == Passenger.infantType && age >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Infant must be under 2 years old on travel date (age: $age)',
              ),
            ),
          );
        } else if (passengerType == Passenger.childType &&
            (age < 2 || age > 17)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Child must be between 2 and 17 years old on travel date (age: $age)',
              ),
            ),
          );
        }
      }
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
      passengers: _passengerSelections.length,
      cabinClass: _cabinClass,
    );

    context.read<FlightSearchBloc>().add(FlightSearchRequested(criteria));
  }

  void _onResultsLoaded(FlightSearchLoaded state) {
    final session = getIt<BookingSession>();
    session.reset();
    session.searchCriteria = state.criteria;
    session.outboundFlights = state.flights;

    final selected = <Map<String, dynamic>>[];
    for (final id in _passengerSelections) {
      if (id == null) continue;
      if (id == '-1') {
        if (_loggedInTraveller != null) {
          selected.add(_loggedInTraveller!);
        }
      } else {
        final parsed = int.tryParse(id);
        if (parsed != null) {
          final traveller = _savedTravellers.firstWhere(
            (t) => (t['id'] ?? 0) == parsed,
            orElse: () => <String, dynamic>{},
          );
          if (traveller.isNotEmpty) {
            selected.add(traveller);
          }
        }
      }
    }
    session.selectedTravelers = selected;

    if (state.flights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flights found for your search.')),
      );
      return;
    }

    context.push('/flights/results');
  }

  Widget _buildOtherSearchSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Where do you want to go?',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Search',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.flight_outlined), text: 'Flights'),
              Tab(icon: Icon(Icons.hotel_outlined), text: 'Hotels'),
              Tab(icon: Icon(Icons.directions_car_outlined), text: 'Cars'),
              Tab(icon: Icon(Icons.directions_boat_outlined), text: 'Cruise'),
            ],
          ),
        ),
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
              return TabBarView(
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLocationInput(
                            label: 'From',
                            hint: 'City or airport',
                            controller: _fromController,
                            focusNode: _fromFocusNode,
                            suggestions: _fromSuggestions,
                            showSuggestions: _showFromSuggestions,
                            isFromField: true,
                          ),
                          const SizedBox(height: 16),
                          _buildLocationInput(
                            label: 'To',
                            hint: 'City or airport',
                            controller: _toController,
                            focusNode: _toFocusNode,
                            suggestions: _toSuggestions,
                            showSuggestions: _showToSuggestions,
                            isFromField: false,
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _passengersExpanded =
                                        !_passengersExpanded);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Passenger',
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${_passengerSelections.length} Passenger${_passengerSelections.length > 1 ? 's' : ''}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _passengersExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            iconSize: 20,
                                            onPressed: () {
                                              setState(() {
                                                _passengerSelections.add(null);
                                                _passengersExpanded = true;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_passengersExpanded) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ..._buildPassengerSlots(),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _passengerSelections.add(null);
                                            });
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add passenger'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _cabinClass,
                            decoration: const InputDecoration(
                              labelText: 'Cabin Class',
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            items: _cabinClassOptions
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _cabinClass = value);
                              }
                            },
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
                  ),
                  _buildOtherSearchSection(
                    icon: Icons.hotel_outlined,
                    title: 'Search hotels',
                    description: 'Find the right stay for your trip.',
                  ),
                  _buildOtherSearchSection(
                    icon: Icons.directions_car_outlined,
                    title: 'Search cars',
                    description: 'Choose a car for your journey.',
                  ),
                  _buildOtherSearchSection(
                    icon: Icons.directions_boat_outlined,
                    title: 'Search cruises',
                    description: 'Discover your next cruise adventure.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewTravellerController {
  final relationship = TextEditingController();
  final passengerType = TextEditingController(text: 'Adult');
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final dateOfBirth = TextEditingController();
  final nationality = TextEditingController();
  final passportNumber = TextEditingController();
  final issueNumber = TextEditingController();
  final passportExpiryDate = TextEditingController();
  final frequencyFlyerNo = TextEditingController();
  final knownTravellerNo = TextEditingController();
  final specialRequirement = TextEditingController();

  void dispose() {
    relationship.dispose();
    passengerType.dispose();
    firstName.dispose();
    lastName.dispose();
    dateOfBirth.dispose();
    nationality.dispose();
    passportNumber.dispose();
    issueNumber.dispose();
    passportExpiryDate.dispose();
    frequencyFlyerNo.dispose();
    knownTravellerNo.dispose();
    specialRequirement.dispose();
  }
}
