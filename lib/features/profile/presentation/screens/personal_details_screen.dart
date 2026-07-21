import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DetailRow(label: 'First name', value: 'John'),
          _DetailRow(label: 'Last name', value: 'Doe'),
          _DetailRow(label: 'Address', value: '123 Main St, Colombo, Sri Lanka'),
          _DetailRow(label: 'Email', value: 'john.doe@example.com'),
          _DetailRow(label: 'Mobile Number', value: '+94 77 123 4567'),
          _DetailRow(label: 'Gender', value: 'Male'),
          _DetailRow(label: 'NIC', value: '199012345678'),
          _DetailRow(label: 'Passport number', value: 'N1234567'),
        ],
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
