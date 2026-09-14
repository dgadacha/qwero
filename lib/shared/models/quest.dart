import 'package:freezed_annotation/freezed_annotation.dart';

import '../photos/scene.dart';
import 'enums.dart';

part 'quest.freezed.dart';

/// Critère affiché avant participation (§30) et évalué par QuestCheck (§35).
@freezed
abstract class QuestRequirement with _$QuestRequirement {
  const factory QuestRequirement({
    required String id,
    required String label,
    required String emoji,
  }) = _QuestRequirement;
}

/// Une quête (§14, §73).
@freezed
abstract class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required QuestCategory category,
    required QuestDifficulty difficulty,
    required int xpReward,
    required int estimatedMinutes,
    required Scene scene,
    @Default(ProofType.photo) ProofType proofType,
    @Default(false) bool galleryAllowed,
    @Default(<QuestRequirement>[]) List<QuestRequirement> requirements,
    @Default(0) int participantCount,
    DateTime? expiresAt,
    String? worldNumber,
  }) = _Quest;

  const Quest._();

  /// Temps restant avant expiration, pour l'affichage du compte à rebours (§29).
  Duration? get timeLeft {
    final end = expiresAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

/// Le set du jour (§11). Trois quêtes + une World Quest (§129).
@freezed
abstract class DailyQuestSet with _$DailyQuestSet {
  const factory DailyQuestSet({
    required String id,
    required DateTime date,
    required Quest easy,
    required Quest medium,
    required Quest hard,
    required Quest world,
  }) = _DailyQuestSet;

  const DailyQuestSet._();

  List<Quest> get all => [easy, medium, hard, world];

  /// Les trois quêtes quotidiennes, World Quest exclue.
  List<Quest> get daily => [easy, medium, hard];
}
