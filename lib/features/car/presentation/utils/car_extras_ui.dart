import 'package:flutter/material.dart';

/// Maps the web `ExtraOption.icon` string (lucide names) to Material icons so
/// the car add-ons list renders an appropriate leading icon.
IconData extraIconFor(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'baby':
    case 'child':
      return Icons.child_care;
    case 'users':
    case 'user':
      return Icons.group;
    case 'wrench':
    case 'tools':
      return Icons.build_circle;
    case 'wifi':
      return Icons.wifi;
    case 'shield':
    case 'shield-check':
    case 'protection':
      return Icons.shield;
    case 'navigation':
    case 'gps':
      return Icons.navigation;
    case 'bag':
    case 'luggage':
    case 'baggage':
      return Icons.work;
    case 'snowflake':
      return Icons.ac_unit;
    case 'speed':
    case 'odometer':
      return Icons.speed;
    case 'plus':
    default:
      return Icons.add_circle_outline;
  }
}

/// Renders a per-day / per-rental / included price line for an extra.
String formatExtraPrice({
  required double pricePerDay,
  required String priceType,
  required int rentalDays,
}) {
  if (pricePerDay <= 0) return 'Included';
  final unit = '£${pricePerDay.toStringAsFixed(pricePerDay % 1 == 0 ? 0 : 2)}';
  if (priceType == 'per_day') {
    if (rentalDays > 1) {
      final total = pricePerDay * rentalDays;
      return '$unit/day (£${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)} for $rentalDays days)';
    }
    return '$unit/day';
  }
  return '$unit for rental';
}
