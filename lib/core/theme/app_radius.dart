import 'package:flutter/widgets.dart';

/// Design tokens — rayons (§144).
abstract final class AppRadius {
  static const chip = 999.0;
  static const small = 8.0;
  static const button = 16.0;
  static const card = 20.0;
  static const modal = 28.0;

  static const chipR = BorderRadius.all(Radius.circular(chip));
  static const smallR = BorderRadius.all(Radius.circular(small));
  static const buttonR = BorderRadius.all(Radius.circular(button));
  static const cardR = BorderRadius.all(Radius.circular(card));
  static const modalR = BorderRadius.only(
    topLeft: Radius.circular(modal),
    topRight: Radius.circular(modal),
  );
}
