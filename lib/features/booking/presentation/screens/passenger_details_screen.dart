import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final List<_PassengerFormController> _controllers = [];
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactCountryController = TextEditingController(text: 'Sri Lanka');
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
    _apiClient = getIt<ApiClient>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileAndInitForms());
  }

  Future<void> _loadProfileAndInitForms() async {
    final passengerCount = _session.searchCriteria?.passengers ?? 1;
    final authState = context.read<AuthBloc>().state;

    Map<String, dynamic>? profile;

    try {
      final response = await _apiClient.get<dynamic>('/profile/personal');
      if (response.data != null && response.data is Map) {
        profile = response.data as Map<String, dynamic>;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load profile data. Using saved data.';
        });
      }
    }

    for (var i = 0; i < passengerCount; i++) {
      final c = _PassengerFormController();
      if (i == 0 && authState is AuthAuthenticated) {
        final user = authState.user;
        final parts = user.name.split(' ');

        c.firstName.text = profile?['firstName'] as String? ??
            (parts.isNotEmpty ? parts.first : '');
        c.lastName.text = profile?['lastName'] as String? ??
            (parts.length > 1 ? parts.sublist(1).join(' ') : '');

        final email = profile?['email'] as String? ?? user.username;
        c.email.text = email ?? '';
        _contactEmailController.text = email ?? '';

        final phone = profile?['phone'] as String?;
        if (phone != null) {
          c.phone.text = phone;
          _contactPhoneController.text = phone;
        }

        final country = profile?['country'] as String? ??
            profile?['nationality'] as String? ??
            'Sri Lanka';
        c.country.text = country ?? 'Sri Lanka';
        _contactCountryController.text = c.country.text;

        final dobStr = profile?['dateOfBirth'] as String?;
        if (dobStr != null) {
          final dob = DateTime.tryParse(dobStr);
          if (dob != null) {
            c.dateOfBirth = dob;
            c.dob.text = DateFormat('yyyy-MM-dd').format(dob);
          }
        }

        final passportNum = profile?['passportNumber'] as String?;
        if (passportNum != null) {
          c.passport.text = passportNum;
        }

        final passportExpiryStr = profile?['passportExpiryDate'] as String?;
        if (passportExpiryStr != null) {
          c.passportExpiry = DateTime.tryParse(passportExpiryStr);
        }
      }
      _controllers.add(c);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _next() {
    final hasEmptyLead = _controllers.first.firstName.text.trim().isEmpty ||
        _controllers.first.lastName.text.trim().isEmpty;

    if (hasEmptyLead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all passenger names')),
      );
      return;
    }

    final passengers = _controllers.map((c) {
      return Passenger(
        firstName: c.firstName.text.trim(),
        lastName: c.lastName.text.trim(),
        email: c.email.text.trim().isEmpty ? null : c.email.text.trim(),
        phone: c.phone.text.trim().isEmpty ? null : c.phone.text.trim(),
        dateOfBirth: c.dateOfBirth,
        passportNumber:
            c.passport.text.trim().isEmpty ? null : c.passport.text.trim(),
        passportExpiry: c.passportExpiry,
        country: c.country.text.trim().isEmpty ? null : c.country.text.trim(),
      );
    }).toList();

    _session.passengers = passengers;
    _session.contactEmail = _contactEmailController.text.trim();
    _session.contactPhone = _contactPhoneController.text.trim();
    _session.contactCountry = _contactCountryController.text.trim();

    context.push('/booking/summary');
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = _session.selectedOutboundFlight;
    final passengerCount = _session.searchCriteria?.passengers ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Passenger details')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SafeArea(
                  child: SingleChildScrollView(
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
                                  Icon(
                                    Icons.flight_takeoff,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                        if (_loadError != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _loadError!,
                              style: AppTextStyles.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        Text('Passenger details', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _controllers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = _controllers[index];
                            return _buildPassengerForm(
                              index,
                              c,
                              isLead: index == 0,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_controllers.length < 9)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _controllers.add(_PassengerFormController());
                              });
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add another passenger'),
                          ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text('Contact details', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactEmailController,
                          decoration:
                              const InputDecoration(labelText: 'Email address'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactPhoneController,
                          decoration:
                              const InputDecoration(labelText: 'Phone number'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactCountryController,
                          decoration: const InputDecoration(
                              labelText: 'Country of residence'),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Continue',
                          isLoading: false,
                          onPressed: _next,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPassengerForm(
    int index,
    _PassengerFormController c, {
    bool isLead = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLead ? 'Lead passenger' : 'Passenger ${index + 1}',
              style: AppTextStyles.h4,
            ),
            if (isLead) ...[
              const SizedBox(height: 4),
              Text(
                'Pre-filled from your profile',
                style: AppTextStyles.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
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
              decoration:
                  const InputDecoration(labelText: 'Email address'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.phone,
              decoration:
                  const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.passport,
              decoration:
                  const InputDecoration(labelText: 'Passport number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.country,
              decoration:
                  const InputDecoration(labelText: 'Country of residence'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.dob,
              readOnly: true,
              onTap: () => _pickDateOfBirth(c),
              decoration:
                  const InputDecoration(labelText: 'Date of birth'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth(_PassengerFormController c) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: c.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        c.dateOfBirth = picked;
        c.dob.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
}

class _PassengerFormController {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final passport = TextEditingController();
  final country = TextEditingController();
  final dob = TextEditingController();
  DateTime? dateOfBirth;
  DateTime? passportExpiry;

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    passport.dispose();
    country.dispose();
    dob.dispose();
  }
}
