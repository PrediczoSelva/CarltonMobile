import 'package:flutter/material.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier({Locale initial = const Locale('en')}) : super(initial);

  void setLocale(Locale locale) {
    value = locale;
  }
}
