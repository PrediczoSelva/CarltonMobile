import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/hotel_repository.dart';
import '../../domain/entities/hotel_search_criteria.dart';
import 'hotel_results_screen.dart';

class HotelSearchTab extends StatefulWidget {
  const HotelSearchTab({super.key});

  @override
  State<HotelSearchTab> createState() => _HotelSearchTabState();
}

class _HotelSearchTabState extends State<HotelSearchTab> {
  final _destinationController = TextEditingController();
  final _defaultPlaces = const [
    'London (LON)',
    'Colombo (CMB)',
    'Dubai (DXB)',
    'Singapore (SIN)',
    'Paris (PAR)',
    'Tokyo (TYO)',
    'New York (NYC)',
  ];

  late final HotelRepository _repository;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 10));
  int _rooms = 1;
  bool _loading = false;
  bool _showSuggestions = false;

  static const String _addNewTravellerValue = '__add_new__';

  List<Map<String, dynamic>> _savedTravellers = [];
  Map<String, dynamic>? _loggedInTraveller;
  final List<String?> _travellerSelections = ['-1'];
  bool _travellersExpanded = false;

  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HotelRepository>();
    _apiClient = getIt<ApiClient>();
    _authRepository = getIt<AuthRepository>();
    _loadSavedTravellers();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTravellers() async {
    try {
      final response = await _apiClient.get<dynamic>('/profile/personal');
      if (response.data != null && response.data is Map) {
        _loggedInTraveller = (response.data as Map<String, dynamic>)
          ..['id'] = -1;
      }
    } catch (_) {
      try {
        final user = await _authRepository.getCurrentUser();
        _loggedInTraveller = {
          'id': -1,
          'firstName': '',
          'lastName': '',
          'name': user.name,
        };
      } catch (_) {}
    }

    try {
      final response = await _apiClient.get<dynamic>('/profile/travellers');
      if (response.data != null && response.data is List) {
        _savedTravellers = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .where((t) => (t['id'] != null && t['id'] != -1))
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;
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

  List<Widget> _buildTravellerSlots() {
    return _travellerSelections.asMap().entries.map((entry) {
      final index = entry.key;
      final selectedId = entry.value;
      final isLast = index == _travellerSelections.length - 1;

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
                      setState(() => _travellerSelections[index] = null);
                      _showAddTravellerSheet();
                    } else if (value != null) {
                      setState(() => _travellerSelections[index] = value);
                    }
                  },
                  isExpanded: true,
                ),
              ),
            ),
            if (_travellerSelections.length > 1) const SizedBox(width: 8),
            if (_travellerSelections.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _travellerSelections.removeAt(index);
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
                    final type = controller.passengerType.text.isEmpty
                        ? null
                        : (controller.passengerType.text == 'Child'
                            ? 2
                            : controller.passengerType.text == 'Infant'
                                ? 0
                                : 1);
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
                const SizedBox(height: 12),
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
                                content: Text('Please enter a valid date of birth'),
                              ),
                            );
                            return;
                          }

                          final selectedType = passengerTypeText.isEmpty
                              ? 'Adult'
                              : passengerTypeText;

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
                            final nullIndex = _travellerSelections
                                .indexWhere((s) => s == null);
                            if (nullIndex != -1) {
                              _travellerSelections[nullIndex] = id;
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
    }
  }

  Future<void> _pickDate({required bool checkIn}) async {
    final initial = checkIn ? _checkIn : _checkOut;
    final firstDate = checkIn ? DateTime.now() : _checkIn;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (checkIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  Future<void> _search() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      _showMessage('Please enter a destination.');
      return;
    }
    if (!_checkOut.isAfter(_checkIn)) {
      _showMessage('Check-out must be after check-in.');
      return;
    }

    setState(() => _loading = true);
    try {
      final adults = _travellerSelections
          .map((id) => id != null ? 1 : 0)
          .reduce((a, b) => a + b);
      final criteria = HotelSearchCriteria(
        destination: destination,
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: adults.clamp(1, 8),
        children: 0,
        rooms: _rooms,
      );
      final hotels = await _repository.searchHotels(criteria);
      if (!mounted) return;
      context.push(
        '/hotels/results',
        extra: HotelSearchResultArgs(criteria: criteria, hotels: hotels),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final suggestions = _defaultPlaces
        .where((place) => place.toLowerCase().contains(
              _destinationController.text.trim().toLowerCase(),
            ))
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.hotel_outlined,
                    size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Hotel search', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Search live hotel availability for your trip.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildDestinationField(suggestions),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        'Check-in', _checkIn, () => _pickDate(checkIn: true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDateField('Check-out', _checkOut,
                        () => _pickDate(checkIn: false))),
              ],
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
                      setState(
                          () => _travellersExpanded = !_travellersExpanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Travellers',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_travellerSelections.length} Traveller${_travellerSelections.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _travellersExpanded
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
                                  _travellerSelections.add(null);
                                  _travellersExpanded = true;
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
                  if (_travellersExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._buildTravellerSlots(),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _travellerSelections.add(null);
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add traveller'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Rooms',
                    value: _rooms,
                    max: 5,
                    suffix: 'room',
                    onChanged: (value) {
                      setState(() {
                        _rooms = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Search Hotels',
              isLoading: _loading,
              onPressed: _loading ? null : _search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationField(List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Destination', style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: _destinationController,
          onChanged: (_) => setState(() => _showSuggestions = true),
          onTap: () => setState(() => _showSuggestions = true),
          decoration: const InputDecoration(
            hintText: 'City name or code (e.g. London, LON)',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        if (_showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: suggestions
                  .map(
                    (place) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(place),
                      onTap: () {
                        _destinationController.text = place;
                        setState(() => _showSuggestions = false);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(_formatDate(date)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        max,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text('${index + 1} $suffix${index == 0 ? '' : 's'}'),
        ),
      ),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
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
