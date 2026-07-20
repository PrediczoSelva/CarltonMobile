import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_takeoff, color: AppColors.accent, size: 56),
            const SizedBox(height: 16),
            Text(
              'Carlton Leisure',
              style: AppTextStyles.h2.copyWith(color: AppColors.textOnPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
