import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens — typographie (§92, §195).
abstract final class AppTypography {
  static const family = 'Inter';

  static const hero = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const metadata = TextStyle(
    fontFamily: family,
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
  );

  /// Libellés compacts en capitales (badges, onglets).
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
  );

  /// Titre de carte de quête : capitales, très appuyé (§184).
  static const questTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
}
