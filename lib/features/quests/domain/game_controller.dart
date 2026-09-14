import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/scene.dart';
import '../data/mock_data.dart';
import 'game_state.dart';

/// État de jeu du prototype.
///
/// En phase 2, tout ce qui touche à l'XP, au streak et à la validation part
/// côté Cloud Functions : le serveur reste autoritaire (§8). Ici, on simule.
class GameController extends Notifier<GameState> {
  @override
  GameState build() => GameState(
    user: MockData.me,
    todaySet: MockData.todaySet,
    friends: MockData.friends,
    challenges: MockData.challenges,
    invitations: MockData.invitations,
    activity: MockData.activity,
    completions: {
      for (final quest in MockData.todaySet.all)
        quest.id: MockData.completionsFor(quest.id),
    },
  );

  void completeOnboarding(List<QuestCategory> interests) {
    state = state.copyWith(
      onboardingDone: true,
      user: state.user.copyWith(interests: interests),
    );
  }

  void startQuest(String questId) {
    _setQuestState(questId, (s) => s.copyWith(progress: QuestProgress.inProgress));
  }

  /// Enregistre une participation validée : XP, streak, déverrouillage social.
  void completeQuest({
    required Quest quest,
    required Scene scene,
    required QuestCheckResult result,
    String? caption,
  }) {
    final completion = QuestCompletion(
      id: 'c_me_${quest.id}',
      questId: quest.id,
      author: MockData.dylan,
      scene: scene,
      status: CompletionStatus.validated,
      xpAwarded: quest.xpReward,
      validationScore: result.score,
      caption: caption,
      ago: Duration.zero,
    );

    final user = state.user;
    var xp = user.xp + quest.xpReward;
    var level = user.level;
    while (xp >= AppUser.xpForLevel(level)) {
      xp -= AppUser.xpForLevel(level);
      level += 1;
    }

    // Le streak avance à la première quête du jour (§53).
    final firstOfDay = state.dailyCompletedCount == 0;

    state = state.copyWith(
      user: user.copyWith(
        xp: xp,
        level: level,
        questsCompleted: user.questsCompleted + 1,
        streak: firstOfDay ? user.streak + 1 : user.streak,
      ),
      questStates: {
        ...state.questStates,
        quest.id: UserQuestState(
          progress: QuestProgress.completed,
          myCompletion: completion,
          checkResult: result,
        ),
      },
      completions: {
        ...state.completions,
        quest.id: [completion, ...state.friendCompletions(quest.id)],
      },
    );
  }

  void toggleReaction(String questId, String completionId, String emoji) {
    final list = state.friendCompletions(questId);
    final updated = [
      for (final completion in list)
        if (completion.id != completionId)
          completion
        else
          completion.copyWith(
            reactions: _toggle(completion.reactions, emoji),
          ),
    ];
    state = state.copyWith(completions: {...state.completions, questId: updated});
  }

  List<Reaction> _toggle(List<Reaction> reactions, String emoji) {
    final index = reactions.indexWhere((r) => r.emoji == emoji);
    if (index == -1) {
      return [...reactions, Reaction(emoji: emoji, count: 1, mine: true)];
    }
    final current = reactions[index];
    final next = current.copyWith(
      count: current.mine ? current.count - 1 : current.count + 1,
      mine: !current.mine,
    );
    final result = [...reactions];
    if (next.count <= 0) {
      result.removeAt(index);
    } else {
      result[index] = next;
    }
    return result;
  }

  void addComment(String questId, String completionId, String text) {
    final list = state.friendCompletions(questId);
    final updated = [
      for (final completion in list)
        if (completion.id != completionId)
          completion
        else
          completion.copyWith(
            comments: [
              ...completion.comments,
              QuestComment(
                id: 'cm_${DateTime.now().microsecondsSinceEpoch}',
                author: MockData.dylan,
                text: text,
                ago: Duration.zero,
              ),
            ],
          ),
    ];
    state = state.copyWith(completions: {...state.completions, questId: updated});
  }

  void answerChallenge(String challengeId, {required bool accept}) {
    state = state.copyWith(
      challenges: [
        for (final challenge in state.challenges)
          if (challenge.id != challengeId)
            challenge
          else
            challenge.copyWith(
              state: accept ? ChallengeState.accepted : ChallengeState.declined,
            ),
      ],
    );
  }

  void answerInvitation(String invitationId, {required bool accept}) {
    final invitation = state.invitations.firstWhere((i) => i.id == invitationId);
    state = state.copyWith(
      invitations: state.invitations.where((i) => i.id != invitationId).toList(),
      friends: accept ? [...state.friends, invitation.friend] : state.friends,
    );
  }

  void sendChallenge({required Friend to, required Quest quest}) {
    state = state.copyWith(
      challenges: [
        FriendChallenge(
          id: 'ch_${DateTime.now().microsecondsSinceEpoch}',
          from: to,
          quest: quest,
          state: ChallengeState.pending,
          timeLeft: const Duration(hours: 24),
          outgoing: true,
        ),
        ...state.challenges,
      ],
    );
  }

  void _setQuestState(String questId, UserQuestState Function(UserQuestState) update) {
    state = state.copyWith(
      questStates: {...state.questStates, questId: update(state.stateOf(questId))},
    );
  }
}

final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);

/// Raccourcis de lecture les plus fréquents.
final currentUserProvider = Provider((ref) => ref.watch(gameProvider).user);
final dailySetProvider = Provider((ref) => ref.watch(gameProvider).todaySet);
