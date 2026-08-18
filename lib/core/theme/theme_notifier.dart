import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier({ThemeMode initial = ThemeMode.light}) : super(initial);

  void toggle(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
