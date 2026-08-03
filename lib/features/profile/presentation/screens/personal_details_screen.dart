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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>('/profile/personal');
      setState(() {
        _profile = response.data as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile data.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? value) {
    if (value == null) return '—';
    final dt = DateTime.tryParse(value);
    return dt != null ? DateFormat('MMM d, yyyy').format(dt) : '—';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
