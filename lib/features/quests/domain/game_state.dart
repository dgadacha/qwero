import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';

part 'game_state.freezed.dart';

/// État d'une quête pour le joueur courant.
@freezed
abstract class UserQuestState with _$UserQuestState {
  const factory UserQuestState({
    @Default(QuestProgress.available) QuestProgress progress,
    QuestCompletion? myCompletion,
    QuestCheckResult? checkResult,
  }) = _UserQuestState;

  const UserQuestState._();

  /// Les résultats des amis ne se révèlent qu'après participation (§22).
  bool get revealsFriends => progress == QuestProgress.completed;
}

@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    AppUser? user,
    DailyQuestSet? todaySet,
    @Default(<Friend>[]) List<Friend> friends,
    @Default(<FriendChallenge>[]) List<FriendChallenge> challenges,
    @Default(<FriendInvitation>[]) List<FriendInvitation> invitations,
    @Default(<FriendActivity>[]) List<FriendActivity> activity,
    @Default(<String, UserQuestState>{}) Map<String, UserQuestState> questStates,
    @Default(<String, List<QuestCompletion>>{}) Map<String, List<QuestCompletion>> completions,
    /// Message d'erreur à montrer au joueur, effacé dès qu'il est lu.
    String? error,
  }) = _GameState;

  const GameState._();

  /// L'application a de quoi afficher le tableau des quêtes.
  bool get isReady => user != null && todaySet != null;

  UserQuestState stateOf(String questId) =>
      questStates[questId] ?? const UserQuestState();

  bool isCompleted(String questId) =>
      stateOf(questId).progress == QuestProgress.completed;

  List<QuestCompletion> friendCompletions(String questId) =>
      completions[questId] ?? const [];

  /// Nombre de quêtes du jour terminées (§130).
  int get dailyCompletedCount =>
      todaySet?.all.where((q) => isCompleted(q.id)).length ?? 0;

  int get dailyXpEarned =>
      todaySet?.all.where((q) => isCompleted(q.id)).fold(0, (sum, q) => sum! + q.xpReward) ?? 0;

  int get pendingChallenges =>
      challenges.where((c) => c.state == ChallengeState.pending && !c.outgoing).length;
}
