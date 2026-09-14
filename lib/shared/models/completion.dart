import 'package:freezed_annotation/freezed_annotation.dart';

import '../photos/scene.dart';
import 'enums.dart';
import 'user.dart';

part 'completion.freezed.dart';

/// Une ligne de vérification affichée pendant l'analyse (§37) et après (§38).
@freezed
abstract class QuestCheckItem with _$QuestCheckItem {
  const factory QuestCheckItem({
    required String id,
    required String label,
    required bool passed,
    @Default(1.0) double confidence,
  }) = _QuestCheckItem;
}

/// Réponse de QuestCheck (§35, §36).
@freezed
abstract class QuestCheckResult with _$QuestCheckResult {
  const factory QuestCheckResult({
    required QuestCheckVerdict verdict,
    required double score,
    required List<QuestCheckItem> checks,
    String? reason,
  }) = _QuestCheckResult;
}

/// Une réaction posée sur une participation (§25).
@freezed
abstract class Reaction with _$Reaction {
  const factory Reaction({required String emoji, required int count, @Default(false) bool mine}) =
      _Reaction;
}

@freezed
abstract class QuestComment with _$QuestComment {
  const factory QuestComment({
    required String id,
    required Friend author,
    required String text,
    required Duration ago,
  }) = _QuestComment;
}

/// Une participation à une quête (§75).
@freezed
abstract class QuestCompletion with _$QuestCompletion {
  const factory QuestCompletion({
    required String id,
    required String questId,
    required Friend author,
    required Scene scene,
    required CompletionStatus status,
    @Default(0) int xpAwarded,
    @Default(0.0) double validationScore,
    String? caption,
    @Default(Duration(hours: 1)) Duration ago,
    @Default(<Reaction>[]) List<Reaction> reactions,
    @Default(<QuestComment>[]) List<QuestComment> comments,
    @Default(false) bool isFavorite,
    @Default(QuestVisibility.friends) QuestVisibility visibility,
  }) = _QuestCompletion;

  const QuestCompletion._();

  int get reactionCount => reactions.fold(0, (sum, r) => sum + r.count);
}
