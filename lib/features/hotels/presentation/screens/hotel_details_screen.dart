import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class HotelDetailsScreen extends StatelessWidget {
  const HotelDetailsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hotel, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Hotel ID: $hotelId',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View Offers',
              onPressed: () => context.push('/hotels/$hotelId/offers'),
            ),
          ],
        ),
      ),
    );
  }
}
