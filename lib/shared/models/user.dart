import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'user.freezed.dart';

/// Progression dans une catégorie (§56).
@freezed
abstract class CategoryProgress with _$CategoryProgress {
  const factory CategoryProgress({
    required QuestCategory category,
    required int level,
    required double ratio,
  }) = _CategoryProgress;
}

/// Badge débloqué (§54).
@freezed
abstract class Badge with _$Badge {
  const factory Badge({
    required String id,
    required String emoji,
    required String title,
    required String description,
    @Default(true) bool unlocked,
  }) = _Badge;
}

/// Un joueur (§72).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String username,
    required String displayName,
    required int level,
    required int xp,
    required int streak,
    @Default(0) int questsCompleted,
    @Default(<QuestCategory>[]) List<QuestCategory> interests,
    @Default(<CategoryProgress>[]) List<CategoryProgress> categories,
    @Default(<Badge>[]) List<Badge> badges,
    @Default('Pacific/Noumea') String timezone,
  }) = _AppUser;

  const AppUser._();

  /// XP nécessaire pour le niveau suivant (§51) — restera configurable côté serveur.
  int get xpForNextLevel => xpForLevel(level);

  double get levelRatio => (xp / xpForNextLevel).clamp(0.0, 1.0);

  /// Titre porté par le joueur (§52).
  String get title => switch (level) {
    >= 100 => 'Mythic',
    >= 50 => 'Legend',
    >= 30 => 'Pathfinder',
    >= 20 => 'Adventurer',
    >= 10 => 'Explorer',
    >= 5 => 'Wanderer',
    _ => 'Rookie',
  };

  /// Courbe d'XP (§51). Passera dans Remote Config en phase 2.
  static int xpForLevel(int level) => (100 * math.pow(level, 1.35)).round();
}

/// Un ami (§163). Relation mutuelle, pas de follow.
@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String username,
    required String displayName,
    required int level,
    @Default(0) int streak,
    @Default(0) int questsToday,
  }) = _Friend;
}
