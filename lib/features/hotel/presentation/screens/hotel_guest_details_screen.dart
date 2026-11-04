import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class HotelGuestDetailsScreen extends StatefulWidget {
  const HotelGuestDetailsScreen({super.key});

  @override
  State<HotelGuestDetailsScreen> createState() =>
      _HotelGuestDetailsScreenState();
}

class _HotelGuestDetailsScreenState extends State<HotelGuestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _emergency = TextEditingController();
  final _session = getIt<BookingSession>();
  List<Map<String, dynamic>> _savedGuests = [];
  String _title = 'Mr';
  bool _loadingGuests = true;

  @override
  void initState() {
    super.initState();
    _loadSavedGuests();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGuests() async {
    try {
      final api = getIt<ApiClient>();
      final responses = await Future.wait([
        api.get<dynamic>('/profile/personal'),
        api.get<dynamic>('/profile/travellers'),
      ]);
      final personal = responses[0].data;
      final travellers = responses[1].data;
      final guests = <Map<String, dynamic>>[];
      if (personal is Map) guests.add(Map<String, dynamic>.from(personal));
      if (travellers is List) {
        guests.addAll(
          travellers.whereType<Map>().map(
                (guest) => Map<String, dynamic>.from(guest),
              ),
        );
      }
      if (mounted) {
        setState(() {
          _savedGuests = guests;
          _loadingGuests = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGuests = false);
    }
  }

  String _guestName(Map<String, dynamic> guest) {
    final title = guest['title']?.toString() ?? '';
    final first = guest['firstName']?.toString() ?? '';
    final last = guest['lastName']?.toString() ?? '';
    final name =
        [title, first, last].where((part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? 'Saved guest' : name;
  }

  void _selectSavedGuest(Map<String, dynamic> guest) {
    setState(() {
      _title = guest['title']?.toString() ?? 'Mr';
      _firstName.text = guest['firstName']?.toString() ?? '';
      _lastName.text = guest['lastName']?.toString() ?? '';
      _email.text = guest['email']?.toString() ?? '';
      _phone.text = guest['phone']?.toString() ?? '';
    });
  }

  Future<void> _addNewGuest() async {
    final first = TextEditingController();
    final last = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final guest = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add new guest'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(first, 'First name'),
                _dialogField(last, 'Last name'),
                _dialogField(email, 'Email',
                    keyboardType: TextInputType.emailAddress),
                _dialogField(phone, 'Phone', keyboardType: TextInputType.phone),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, {
                  'title': 'Mr',
                  'firstName': first.text.trim(),
                  'lastName': last.text.trim(),
                  'email': email.text.trim(),
                  'phone': phone.text.trim(),
                });
              }
            },
            child: const Text('Add guest'),
          ),
        ],
      ),
    );
    first.dispose();
    last.dispose();
    email.dispose();
    phone.dispose();
    if (guest == null || !mounted) return;
    setState(() => _savedGuests = [..._savedGuests, guest]);
    _selectSavedGuest(guest);
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter $label' : null;

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _session.hotelLeadGuest = {
      'title': _title,
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
    };
    _session.contactEmail = _email.text.trim();
    _session.contactPhone = _phone.text.trim();
    _session.hotelEmergencyContact = _emergency.text.trim();
    context.push('/hotels/checkout/payment');
  }

  @override
  Widget build(BuildContext context) {
    final offer = _session.selectedHotelOffer;
    final criteria = _session.hotelSearchCriteria;
    final nights = criteria == null
        ? 1
        : criteria.checkOut.difference(criteria.checkIn).inDays;
    return Scaffold(
      appBar: AppBar(title: const Text('Guest details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text('Who is staying?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Select a saved guest or add a new guest for this reservation.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Saved guests', style: AppTextStyles.h4),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addNewGuest,
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Add new'),
                        ),
                      ],
                    ),
                    if (_loadingGuests)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_savedGuests.isEmpty)
                      Text(
                        'No saved guests yet. Add a new guest below.',
                        style: AppTextStyles.bodySmall,
                      )
                    else
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                            labelText: 'Choose a saved guest'),
                        items: [
                          for (var i = 0; i < _savedGuests.length; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(_guestName(_savedGuests[i])),
                            ),
                        ],
                        onChanged: (index) {
                          if (index != null) {
                            _selectSavedGuest(_savedGuests[index]);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Guest 1 — Lead guest',
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  items: ['Mr', 'Mrs', 'Ms', 'Dr']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _title = value ?? 'Mr'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => _required(value, 'first name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) => _required(value, 'last name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                  validator: (value) {
                    if (_required(value, 'mobile number') != null) {
                      return 'Enter mobile number';
                    }
                    return value!.trim().replaceAll(RegExp(r'\D'), '').length <
                            7
                        ? 'Enter a valid mobile number'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Emergency contact',
              children: [
                TextFormField(
                  controller: _emergency,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency contact number',
                  ),
                  validator: (value) {
                    if (_required(value, 'emergency contact number') != null) {
                      return 'Enter emergency contact number';
                    }
                    return value!.replaceAll(RegExp(r'\D'), '').length < 7
                        ? 'Enter a valid emergency contact number'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (offer != null)
              _section(
                title: 'Booking summary',
                children: [
                  _row('Hotel', _session.hotelName ?? 'Hotel'),
                  _row('Room', offer.roomName),
                  _row('Stay', '$nights night${nights == 1 ? '' : 's'}'),
                  _row('Rooms', '${_session.hotelRoomQuantity}'),
                  _row('Total',
                      '£${_session.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
                ],
              ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Continue to payment', onPressed: _continue),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
