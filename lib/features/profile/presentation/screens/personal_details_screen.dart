import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _isEditing = false;
  bool _isSaving = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _passportExpiryController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _dateOfBirthController.dispose();
    _passportNumberController.dispose();
    _passportExpiryController.dispose();
    _countryController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>('/profile/personal');
      setState(() {
        _profile = response.data != null
            ? Map<String, dynamic>.from(response.data as Map)
            : null;
        _isLoading = false;
        _error = null;
      });
      _populateControllers();
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile data.';
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    final p = _profile;
    if (p == null) return;
    final name = p['firstName'] as String? ?? '';
    final parts = name.trim().split(' ');
    _firstNameController.text = parts.isNotEmpty ? parts.first : '';
    _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : (p['lastName'] as String? ?? '');
    _emailController.text = p['email'] as String? ?? '';
    _phoneController.text = p['phone'] as String? ?? '';
    _nationalityController.text = p['nationality'] as String? ?? '';
    _dateOfBirthController.text = p['dateOfBirth'] as String? ?? '';
    _passportNumberController.text = p['passportNumber'] as String? ?? '';
    _passportExpiryController.text = p['passportExpiryDate'] as String? ?? '';
    _countryController.text = p['country'] as String? ?? '';
    _addressLine1Controller.text = p['addressLine1'] as String? ?? '';
    _addressLine2Controller.text = p['addressLine2'] as String? ?? '';
    _cityController.text = p['city'] as String? ?? '';
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    return dt != null ? DateFormat('MMM d, yyyy').format(dt) : '—';
  }

  Future<void> _pickDate(
      BuildContext context, TextEditingController controller) async {
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
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = getIt<ApiClient>();
      final data = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nationality': _nationalityController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'passportNumber': _passportNumberController.text.trim(),
        'passportExpiryDate': _passportExpiryController.text.trim(),
        'country': _countryController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
      };
      await apiClient.put<dynamic>('/profile/personal', data: data);
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal details updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update personal details')),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _populateControllers();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    String name = '—';
    String email = '—';
    if (authState is AuthAuthenticated) {
      name = authState.user.name.isNotEmpty ? authState.user.name : '—';
      email = authState.user.username.isNotEmpty
          ? authState.user.username
          : '—';
    }

    if (_profile != null) {
      final fn = _profile!['firstName'] as String? ?? '';
      final ln = _profile!['lastName'] as String?;
      if (fn.isNotEmpty || (ln != null && ln.isNotEmpty)) {
        name = '$fn ${ln ?? ''}'.trim();
      }
      final profileEmail = _profile!['email'] as String?;
      if (profileEmail != null && profileEmail.isNotEmpty) {
        email = profileEmail;
      }
    }

    final actions = <Widget>[
      if (_isEditing) ...[
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelEdit,
        ),
        IconButton(
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                )
              : const Icon(Icons.check),
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ] else ...[
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() => _isEditing = true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProfile,
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal details'),
        actions: actions,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_isEditing) ...[
                        _EditableField(
                          label: 'First Name',
                          controller: _firstNameController,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Last Name',
                          controller: _lastNameController,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Nationality',
                          controller: _nationalityController,
                        ),
                        const SizedBox(height: 12),
                        _EditableDateField(
                          label: 'Date of Birth',
                          controller: _dateOfBirthController,
                          context: context,
                          onPickDate: () =>
                              _pickDate(context, _dateOfBirthController),
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Passport Number',
                          controller: _passportNumberController,
                        ),
                        const SizedBox(height: 12),
                        _EditableDateField(
                          label: 'Passport Expiry',
                          controller: _passportExpiryController,
                          context: context,
                          onPickDate: () =>
                              _pickDate(context, _passportExpiryController),
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Country of Residence',
                          controller: _countryController,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Address Line 1',
                          controller: _addressLine1Controller,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'Address Line 2',
                          controller: _addressLine2Controller,
                        ),
                        const SizedBox(height: 12),
                        _EditableField(
                          label: 'City',
                          controller: _cityController,
                        ),
                      ] else ...[
                        _DetailRow(label: 'Name', value: name),
                        _DetailRow(label: 'Email', value: email),
                        _DetailRow(
                          label: 'Phone Number',
                          value: _profile?['phone'] as String? ??
                              '+94 77 123 4567',
                        ),
                        _DetailRow(
                          label: 'Nationality',
                          value: _profile?['nationality'] as String? ??
                              'Sri Lankan',
                        ),
                        _DetailRow(
                          label: 'Date of Birth',
                          value: _formatDate(
                              _profile?['dateOfBirth'] as String?),
                        ),
                        _DetailRow(
                          label: 'Passport Number',
                          value: _profile?['passportNumber'] as String? ?? '—',
                        ),
                        _DetailRow(
                          label: 'Passport Expiry',
                          value: _formatDate(
                              _profile?['passportExpiryDate'] as String?),
                        ),
                        _DetailRow(
                          label: 'Country of Residence',
                          value: _profile?['country'] as String? ?? '—',
                        ),
                        _DetailRow(
                          label: 'Address',
                          value: [
                            _profile?['addressLine1'] as String?,
                            _profile?['addressLine2'] as String?,
                            _profile?['city'] as String?,
                            _profile?['country'] as String?,
                          ].where((e) => e != null && e.isNotEmpty).join(', '),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: AppTextStyles.bodySmall),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(value, style: AppTextStyles.bodyLarge)),
          ],
        ),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _EditableDateField extends StatelessWidget {
  const _EditableDateField({
    required this.label,
    required this.controller,
    required this.context,
    required this.onPickDate,
  });

  final String label;
  final TextEditingController controller;
  final BuildContext context;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onPickDate,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
