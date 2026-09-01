import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class HotelOffersScreen extends StatelessWidget {
  const HotelOffersScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offers for Hotel $hotelId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Room offers coming soon',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),
              PrimaryButton(
                label: 'Back to Search',
                onPressed: () => GoRouter.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
