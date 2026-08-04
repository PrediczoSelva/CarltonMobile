import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../booking/domain/entities/booking_session.dart';
import '../../../booking/domain/entities/passenger.dart';

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  late final BookingSession _session;
  late final ApiClient _apiClient;

  bool _isLoading = true;
  Map<String, dynamic>? _personalDetails;
  List<Map<String, dynamic>> _savedTravellers = [];

  final Set<int> _selectedTravellerIds = {};
  final List<_NewTravellerController> _newTravellerForms = [];

  final _contactEmailController = TextEditingController();
  final _contactEmailConfirmController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactCountryController = TextEditingController(text: 'Sri Lanka');

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
    _apiClient = getIt<ApiClient>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await _apiClient.get<dynamic>('/profile/personal');
      if (response.data != null && response.data is Map) {
        _personalDetails = response.data as Map<String, dynamic>;
        final email = _personalDetails!['email'] as String? ?? '';
        final phone = _personalDetails!['phone'] as String? ?? '';
        final country = _personalDetails!['country'] as String? ??
            _personalDetails!['nationality'] as String? ??
            'Sri Lanka';
        _contactEmailController.text = email;
        _contactEmailConfirmController.text = email;
        _contactPhoneController.text = phone;
        _contactCountryController.text = country;
      }
    } catch (_) {}

    try {
      final response = await _apiClient.get<dynamic>('/profile/travellers');
      if (response.data != null && response.data is List) {
        _savedTravellers = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}

    if (_savedTravellers.isEmpty) {
      _savedTravellers = [
        {
          'id': 101,
          'title': 'Mr',
          'firstName': 'Sam',
          'lastName': 'Peterson',
          'dateOfBirth': '1988-05-12',
          'passportNumber': 'N1234567',
          'passportCountry': 'Sri Lanka',
          'nationality': 'Sri Lanka',
        },
      ];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTraveller(int id) {
    setState(() {
      if (_selectedTravellerIds.contains(id)) {
        _selectedTravellerIds.remove(id);
      } else {
        if (_selectedTravellerIds.length + 1 + _newTravellerForms.length >
            (_session.searchCriteria?.passengers ?? 9)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Maximum ${_session.searchCriteria?.passengers ?? 9} passengers allowed.'),
            ),
          );
          return;
        }
        _selectedTravellerIds.add(id);
      }
    });
  }

  void _addNewTraveller() {
    if (_selectedTravellerIds.length + 1 + _newTravellerForms.length >=
        (_session.searchCriteria?.passengers ?? 9)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum ${_session.searchCriteria?.passengers ?? 9} passengers allowed.'),
        ),
      );
      return;
    }

    final controller = _NewTravellerController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add new traveller',
                        style: AppTextStyles.h4,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.dispose();
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the traveller details below.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
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
                  controller: controller.email,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
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

                      setState(() {
                        _newTravellerForms.add(controller);
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
                    child: const Text('Add traveller'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeNewTraveller(int index) {
    setState(() {
      _newTravellerForms[index].dispose();
      _newTravellerForms.removeAt(index);
    });
  }

  Passenger _buildLeadPassenger() {
    final p = _personalDetails;
    if (p == null) {
      final authState = context.read<AuthBloc>().state;
      String firstName = '', lastName = '';
      if (authState is AuthAuthenticated) {
        final parts = authState.user.name.split(' ');
        firstName = parts.isNotEmpty ? parts.first : '';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      return Passenger(firstName: firstName, lastName: lastName);
    }
    final fn = p['firstName'] as String? ?? '';
    final ln = p['lastName'] as String? ?? '';
    return Passenger(
      firstName: fn,
      lastName: ln,
      email: p['email'] as String?,
      phone: p['phone'] as String?,
      dateOfBirth: _parseDate(p['dateOfBirth']),
      passportNumber: p['passportNumber'] as String?,
      passportExpiry: _parseDate(p['passportExpiryDate']),
      country: p['country'] as String? ?? p['nationality'] as String?,
    );
  }

  Passenger _buildTravellerPassenger(Map<String, dynamic> t) {
    final firstName = t['firstName'] as String? ?? '';
    final lastName = t['lastName'] as String? ?? '';
    final fn = firstName;
    final ln = lastName;
    return Passenger(
      firstName: fn,
      lastName: ln,
      dateOfBirth: _parseDate(t['dateOfBirth']),
      passportNumber: t['passportNumber'] as String?,
      passportExpiry: _parseDate(t['passportExpiryDate']),
      country: t['nationality'] as String? ?? t['passportCountry'] as String?,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _continue() {
    final passengers = <Passenger>[];

    passengers.add(_buildLeadPassenger());

    for (final id in _selectedTravellerIds) {
      final traveller = _savedTravellers.firstWhere((t) => t['id'] == id);
      passengers.add(_buildTravellerPassenger(traveller));
    }

    for (final form in _newTravellerForms) {
      final fn = form.firstName.text.trim();
      final ln = form.lastName.text.trim();
      if (fn.isEmpty && ln.isEmpty) continue;
      passengers.add(Passenger(
        firstName: fn,
        lastName: ln,
        email: form.email.text.trim().isEmpty ? null : form.email.text.trim(),
        phone: form.phone.text.trim().isEmpty ? null : form.phone.text.trim(),
      ));
    }

    final emptyNames = passengers
        .where((p) => p.firstName.trim().isEmpty || p.lastName.trim().isEmpty);
    if (emptyNames.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all passenger names')),
      );
      return;
    }

    final email = _contactEmailController.text.trim();
    if (email.isNotEmpty &&
        email != _contactEmailConfirmController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email addresses do not match')),
      );
      return;
    }

    _session.passengers = passengers;
    _session.contactEmail = email;
    _session.contactPhone = _contactPhoneController.text.trim();
    _session.contactCountry = _contactCountryController.text.trim();

    context.push('/booking/summary');
  }

  String _travellerName(Map<String, dynamic> t) {
    final parts = <String>[];
    final title = t['title'] as String?;
    if (title != null && title.isNotEmpty) parts.add(title);
    final fn = t['firstName'] as String? ?? '';
    if (fn.isNotEmpty) parts.add(fn);
    final ln = t['lastName'] as String? ?? '';
    if (ln.isNotEmpty) parts.add(ln);
    return parts.join(' ');
  }

  String _leadName() {
    if (_personalDetails != null) {
      final p = _personalDetails!;
      final title = p['title'] as String?;
      final fn = p['firstName'] as String? ?? '';
      final ln = p['lastName'] as String? ?? '';
      final parts = <String>[
        if (title != null && title.isNotEmpty) title,
        fn,
        ln,
      ].where((e) => e.isNotEmpty);
      return parts.join(' ');
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.name;
    }
    return 'Lead Passenger';
  }

  @override
  void dispose() {
    for (final f in _newTravellerForms) {
      f.dispose();
    }
    _contactEmailController.dispose();
    _contactEmailConfirmController.dispose();
    _contactPhoneController.dispose();
    _contactCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = _session.selectedOutboundFlight;

    return Scaffold(
      appBar: AppBar(title: const Text('Passenger details')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (flight != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.flight_takeoff,
                                color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${flight.airline} ${flight.flightCode}',
                                    style: AppTextStyles.h4,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${flight.origin} → ${flight.destination}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${flight.currency} ${flight.price.toStringAsFixed(0)}',
                              style: AppTextStyles.price,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick fill from saved travellers',
                                    style: AppTextStyles.h4,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pick a saved traveller to prefill passenger details.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSavedTravellerCards(),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _addNewTraveller,
                          icon: const Icon(Icons.person_add_alt_1_outlined,
                              size: 18),
                          label: const Text('Add new traveller'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Selected travellers', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 8),
                  _buildSelectedSection(),
                  const SizedBox(height: 24),
                  Text('Contact Details', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Booking confirmation and e-tickets sent here',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactEmailController,
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactEmailConfirmController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactPhoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactCountryController,
                    decoration: const InputDecoration(
                        labelText: 'Country of Residence'),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Continue',
                    isLoading: false,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _buildSavedTravellerCards() {
    final allTravellers = <Map<String, dynamic>?>[null, ..._savedTravellers];

    if (allTravellers.length == 1) {
      return Text(
        'No saved travellers found yet. Add details below.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: List.generate(allTravellers.length, (index) {
        final traveller = allTravellers[index];
        if (traveller == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _travellerCard(
              name: _leadName(),
              subtitle: 'Lead passenger profile',
              isSelected: true,
              onTap: () {},
              showCheckbox: false,
            ),
          );
        }
        final id = traveller['id'] as int? ?? index;
        final isSelected = _selectedTravellerIds.contains(id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _travellerCard(
            name: _travellerName(traveller),
            subtitle: 'Saved traveller',
            isSelected: isSelected,
            onTap: () => _toggleTraveller(id),
            showCheckbox: true,
          ),
        );
      }),
    );
  }

  Widget _travellerCard({
    required String name,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool showCheckbox = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.25)
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showCheckbox)
                  Transform.scale(
                    scale: 0.95,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onTap(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSection() {
    final selectedWidgets = <Widget>[
      _selectedCard(name: _leadName(), subtitle: 'Lead passenger'),
    ];

    for (final id in _selectedTravellerIds) {
      final traveller =
          _savedTravellers.firstWhere((t) => t['id'] == id, orElse: () => {});
      selectedWidgets.add(_selectedCard(
        name: _travellerName(traveller),
        subtitle: 'Saved traveller',
      ));
    }

    for (final form in _newTravellerForms) {
      final fn = form.firstName.text.trim();
      final ln = form.lastName.text.trim();
      final name = '$fn $ln'.trim();
      if (name.isNotEmpty) {
        selectedWidgets.add(_selectedCard(
          name: name,
          subtitle: 'New traveller',
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () =>
                _removeNewTraveller(_newTravellerForms.indexOf(form)),
          ),
        ));
      }
    }

    for (final form in _newTravellerForms) {
      selectedWidgets.add(_buildNewTravellerForm(form));
    }

    if (selectedWidgets.length == 1) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No passengers selected yet. Choose a saved traveller or add one below.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedWidgets,
      ),
    );
  }

  Widget _selectedCard({
    required String name,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildNewTravellerForm(_NewTravellerController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Traveller',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.firstName,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.email,
              decoration: const InputDecoration(labelText: 'Email address'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTravellerController {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
  }
}
