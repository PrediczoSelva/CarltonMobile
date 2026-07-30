import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal details')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildDetails(context, state.user);
          }
          return const Center(child: Text('No user data available'));
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, UserEntity user) {
    final parts = user.name.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailRow(label: 'First name', value: firstName),
        _DetailRow(label: 'Last name', value: lastName),
        _DetailRow(label: 'Email', value: user.username),
        _DetailRow(label: 'Role', value: user.role),
      ],
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
