import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens — ombres et halos.
abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  /// Halo violet sous les CTA principaux (§95).
  static List<BoxShadow> primaryGlow({double opacity = 0.38}) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: opacity),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.35, double blur = 28}) => [
    BoxShadow(color: color.withValues(alpha: opacity), blurRadius: blur),
  ];
}
