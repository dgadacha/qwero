import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/quests/data/mock_data.dart';
import 'package:quest/features/quests/data/mock_repository.dart';
import 'package:quest/features/quests/domain/game_controller.dart';
import 'package:quest/shared/models/enums.dart';
import 'package:quest/shared/models/quest.dart';
import 'package:quest/shared/models/social.dart';
import 'package:quest/shared/photos/scene.dart';

/// Boucle de jeu, telle qu'elle se comporte sur la source mockée.
///
/// Les mêmes actions passent par des Cloud Functions en mode Firebase : ces
/// tests vérifient l'enchaînement côté client, pas les règles de récompense,
/// qui sont couvertes côté serveur.
void main() {
  late ProviderContainer container;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWith((_) => repository)],
    );
    // Force la construction du contrôleur et de ses abonnements.
    container.read(gameProvider);
  });

  tearDown(() => container.dispose());

  GameController controller() => container.read(gameProvider.notifier);

  Future<void> complete(Quest quest, Scene scene) async {
    repository.pendingScene = scene;
    await controller().submitProof(
      quest: quest,
      imageBytes: Uint8List(0),
      capturedAt: DateTime.now(),
    );
    // Laisse les flux propager l'état.
    await Future<void>.delayed(Duration.zero);
  }

  test("une quête réussie attribue son XP et fait avancer le streak", () async {
    final before = repository.user;

    await complete(MockData.hard, Scene.sunsetOcean);

    final after = repository.user;
    expect(after.xp, before.xp + MockData.hard.xpReward);
    expect(after.streak, before.streak + 1);
    expect(after.questsCompleted, before.questsCompleted + 1);
  });

  test("une photo hors-sujet n'attribue rien", () async {
    final before = repository.user;

    await complete(MockData.hard, Scene.coffee);

    expect(repository.user.xp, before.xp);
    expect(repository.user.streak, before.streak);
    expect(container.read(gameProvider).isCompleted(MockData.hard.id), isFalse);
  });

  test('le streak ne monte pas deux fois le même jour', () async {
    final before = repository.user.streak;

    await complete(MockData.easy, Scene.redCar);
    await complete(MockData.medium, Scene.openRoad);

    expect(repository.user.streak, before + 1);
  });

  test("les résultats des amis restent masqués tant qu'on n'a pas participé", () async {
    expect(
      container.read(gameProvider).stateOf(MockData.hard.id).revealsFriends,
      isFalse,
    );

    await complete(MockData.hard, Scene.sunsetOcean);

    expect(
      container.read(gameProvider).stateOf(MockData.hard.id).revealsFriends,
      isTrue,
    );
  });

  test('sa propre participation ouvre le fil de la quête', () async {
    final before = repository.completionsOf(MockData.hard.id).length;

    await complete(MockData.hard, Scene.sunsetOcean);

    final after = repository.completionsOf(MockData.hard.id);
    expect(after.length, before + 1);
    expect(after.first.author.id, repository.currentUserId);
  });

  test('une réaction peut être posée puis retirée', () async {
    final completion = repository.completionsOf(MockData.hard.id).first;
    final before = completion.reactions.length;

    await controller().toggleReaction(MockData.hard.id, completion.id, '👏');
    var updated = repository
        .completionsOf(MockData.hard.id)
        .firstWhere((c) => c.id == completion.id);
    expect(updated.reactions.length, before + 1);
    expect(updated.reactions.last.mine, isTrue);

    await controller().toggleReaction(MockData.hard.id, completion.id, '👏');
    updated = repository
        .completionsOf(MockData.hard.id)
        .firstWhere((c) => c.id == completion.id);
    expect(updated.reactions.length, before);
  });

  test('accepter une invitation ajoute la personne aux amis', () async {
    final invitation = repository.invitations.first;
    final before = repository.friends.length;

    await controller().answerInvitation(invitation.id, accept: true);

    expect(repository.friends.length, before + 1);
    expect(repository.invitations.any((i) => i.id == invitation.id), isFalse);
  });

  test('refuser un challenge le marque comme refusé', () async {
    final challenge = repository.challenges.firstWhere(
      (c) => c.state == ChallengeState.pending,
    );

    await controller().answerChallenge(challenge.id, accept: false);

    final updated = repository.challenges.firstWhere((c) => c.id == challenge.id);
    expect(updated.state, ChallengeState.declined);
  });

  test('les intérêts choisis sont enregistrés', () async {
    await controller().completeOnboarding([
      QuestCategory.nature,
      QuestCategory.gaming,
      QuestCategory.food,
    ]);

    expect(repository.user.interests, hasLength(3));
    expect(repository.user.interests, contains(QuestCategory.nature));
  });
}
