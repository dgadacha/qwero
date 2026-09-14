import 'package:flutter/material.dart';

/// Design tokens — couleurs (§89 à §91, §194).
///
/// Aucun composant ne doit définir une couleur principale en dur :
/// tout passe par cette classe.
abstract final class AppColors {
  // Fonds
  static const background = Color(0xFF080C14);
  static const surface1 = Color(0xFF101722);
  static const surface2 = Color(0xFF151D2A);
  static const surface3 = Color(0xFF1B2534);

  // Marque
  static const primary = Color(0xFF7357FF);
  static const primaryLight = Color(0xFF917BFF);
  static const primaryDark = Color(0xFF5638F5);

  // Couleurs fonctionnelles
  static const easy = Color(0xFF2DD4A8);
  static const medium = Color(0xFFF5C84C);
  static const hard = Color(0xFFFF5368);
  static const world = Color(0xFF4CA8F5);
  static const xp = Color(0xFFFFD65A);
  static const success = Color(0xFF5DE2B3);
  static const streak = Color(0xFFFF8A3D);

  // Texte
  static const textPrimary = Color(0xFFF4F6FB);
  static const textSecondary = Color(0xFF9AA6BE);
  static const textTertiary = Color(0xFF61708C);

  // Bordures (§145)
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x1FFFFFFF);
  static const borderPrimary = Color(0x667357FF);

  // Dégradé principal (§90)
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7657FF), Color(0xFF5638F5)],
  );

  /// Voile sombre posé sur les photographies immersives.
  static const photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00080C14), Color(0x99080C14), Color(0xF2080C14)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Couleurs des confettis (§99).
  static const confetti = <Color>[
    primary,
    easy,
    xp,
    Color(0xFFFF6FB5),
    Color(0xFF4CA8F5),
  ];
}
