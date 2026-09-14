import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_mode.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/user.dart';
import '../data/firestore_repository.dart';
import '../data/mock_repository.dart';
import '../data/quest_repository.dart';
import 'game_state.dart';

/// Source de données active. Le mode se choisit au lancement (§125).
final repositoryProvider = Provider<QuestRepository>((ref) {
  final repository =
      Backend.isFirebase ? FirestoreRepository() : MockRepository();
  return repository;
});

/// État de jeu.
///
/// Le contrôleur n'applique aucune règle de récompense : il relaie les actions
/// au serveur et reflète ce que celui-ci décide (§8). En mode mocké, la même
/// interface est servie en mémoire.
class GameController extends Notifier<GameState> {
  final _subscriptions = <StreamSubscription<void>>[];

  QuestRepository get _repository => ref.read(repositoryProvider);

  @override
  GameState build() {
    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });

    _bind();
    return _initialState();
  }

  /// Premier rendu immédiat en mode mocké ; écran de chargement sinon.
  GameState _initialState() {
    final repository = _repository;
    if (repository is! MockRepository) return const GameState();

    return GameState(
      user: repository.user,
      todaySet: null,
      friends: repository.friends,
      challenges: repository.challenges,
      invitations: repository.invitations,
      activity: repository.activity,
      completions: {
        for (final quest in _mockQuestIds(repository))
          quest: repository.completionsOf(quest),
      },
    );
  }

  List<String> _mockQuestIds(MockRepository repository) => const [
        'q_easy_849',
        'q_medium_221',
        'q_hard_922',
        'world_184',
      ];

  void _bind() {
    final repository = _repository;

    _listen(repository.watchUser(), (user) => state = state.copyWith(user: user));

    _listen(repository.watchDailySet(), (set) {
      state = state.copyWith(todaySet: set);
      // Les participations d'une quête ne sont suivies qu'une fois la quête
      // connue : inutile d'ouvrir des écoutes sur des identifiants inconnus.
      for (final quest in set.all) {
        _watchCompletions(quest.id);
      }
    });

    _listen(repository.watchQuestStates(), (states) {
      state = state.copyWith(
        questStates: {
          for (final entry in states.entries)
            entry.key: state.stateOf(entry.key).copyWith(progress: entry.value),
        },
      );
    });

    _listen(repository.watchFriends(), (friends) => state = state.copyWith(friends: friends));
    _listen(repository.watchActivity(), (activity) => state = state.copyWith(activity: activity));
    _listen(
      repository.watchChallenges(),
      (challenges) => state = state.copyWith(challenges: challenges),
    );
    _listen(
      repository.watchInvitations(),
      (invitations) => state = state.copyWith(invitations: invitations),
    );
  }

  final _watchedQuests = <String>{};

  void _watchCompletions(String questId) {
    if (!_watchedQuests.add(questId)) return;
    _listen(_repository.watchCompletions(questId), (completions) {
      state = state.copyWith(
        completions: {...state.completions, questId: completions},
      );
    });
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onData) {
    _subscriptions.add(
      stream.listen(
        onData,
        onError: (Object error) => state = state.copyWith(error: _message(error)),
      ),
    );
  }

  String _message(Object error) =>
      error is RepositoryException ? error.message : 'Une erreur est survenue.';

  void clearError() => state = state.copyWith(error: null);

  // ------------------------------------------------------------- actions

  Future<void> completeOnboarding(List<QuestCategory> interests) =>
      _guard(() => _repository.saveInterests(interests));

  Future<void> startQuest(String questId) => _guard(() => _repository.startQuest(questId));

  /// Dépose une preuve et rend l'identifiant de la participation à suivre.
  Future<String?> submitProof({
    required Quest quest,
    required Uint8List imageBytes,
    required DateTime capturedAt,
  }) async {
    try {
      return await _repository.submitProof(
        quest: quest,
        imageBytes: imageBytes,
        capturedAt: capturedAt,
      );
    } catch (error) {
      state = state.copyWith(error: _message(error));
      return null;
    }
  }

  Stream<QuestCompletion> watchCompletion(String completionId) =>
      _repository.watchCompletion(completionId);

  Future<void> toggleReaction(String questId, String completionId, String emoji) =>
      _guard(() => _repository.toggleReaction(questId, completionId, emoji));

  Future<void> addComment(String questId, String completionId, String text) =>
      _guard(() => _repository.addComment(questId, completionId, text));

  Future<void> answerChallenge(String challengeId, {required bool accept}) =>
      _guard(() => _repository.answerChallenge(challengeId, accept: accept));

  Future<void> answerInvitation(String invitationId, {required bool accept}) =>
      _guard(() => _repository.answerInvitation(invitationId, accept: accept));

  Future<void> sendChallenge({required Friend to, required String text}) =>
      _guard(() => _repository.sendChallenge(to: to, text: text));

  Future<void> contest(String completionId) =>
      _guard(() => _repository.contest(completionId));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      state = state.copyWith(error: _message(error));
    }
  }
}

final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);

/// Raccourcis de lecture les plus fréquents.
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(gameProvider).user);
final dailySetProvider = Provider<DailyQuestSet?>((ref) => ref.watch(gameProvider).todaySet);
