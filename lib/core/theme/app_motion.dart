import 'package:flutter/animation.dart';

/// Design tokens — animation (§142, §196).
abstract final class AppMotion {
  /// Micro-interactions : 100–180 ms.
  static const micro = Duration(milliseconds: 140);
  static const microSlow = Duration(milliseconds: 180);

  /// Transitions d'écran : 200–300 ms.
  static const screen = Duration(milliseconds: 260);

  /// Moments de récompense : 800–1600 ms.
  static const reward = Duration(milliseconds: 1400);

  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const standard = Curves.easeOutCubic;
  static const springy = Curves.easeOutBack;
}
