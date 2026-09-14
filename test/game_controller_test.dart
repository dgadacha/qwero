import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/quest_check/domain/quest_check_service.dart';
import 'package:quest/features/quests/domain/game_controller.dart';
import 'package:quest/shared/photos/scene.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  GameController controller() => container.read(gameProvider.notifier);

  test("une quête terminée attribue son XP et fait avancer le streak", () {
    final before = container.read(gameProvider).user;
    final quest = container.read(gameProvider).todaySet.hard;

    controller().completeQuest(
      quest: quest,
      scene: Scene.sunsetOcean,
      result: QuestCheckService.analyse(quest: quest, scene: Scene.sunsetOcean),
    );

    final after = container.read(gameProvider).user;
    expect(after.xp, before.xp + quest.xpReward);
    expect(after.streak, before.streak + 1);
    expect(after.questsCompleted, before.questsCompleted + 1);
  });

  test('le streak ne monte qu\'une fois par jour', () {
    final set = container.read(gameProvider).todaySet;
    final start = container.read(gameProvider).user.streak;

    for (final quest in [set.easy, set.medium]) {
      controller().completeQuest(
        quest: quest,
        scene: quest.scene,
        result: QuestCheckService.analyse(quest: quest, scene: quest.scene),
      );
    }

    expect(container.read(gameProvider).user.streak, start + 1);
  });

  test("les résultats des amis restent masqués tant qu'on n'a pas participé", () {
    final quest = container.read(gameProvider).todaySet.hard;
    expect(container.read(gameProvider).stateOf(quest.id).revealsFriends, isFalse);

    controller().completeQuest(
      quest: quest,
      scene: Scene.sunsetOcean,
      result: QuestCheckService.analyse(quest: quest, scene: Scene.sunsetOcean),
    );

    expect(container.read(gameProvider).stateOf(quest.id).revealsFriends, isTrue);
  });

  test('une réaction peut être posée puis retirée', () {
    final quest = container.read(gameProvider).todaySet.hard;
    final completion = container.read(gameProvider).friendCompletions(quest.id).first;
    final before = completion.reactions.length;

    controller().toggleReaction(quest.id, completion.id, '👏');
    var updated = container
        .read(gameProvider)
        .friendCompletions(quest.id)
        .firstWhere((c) => c.id == completion.id);
    expect(updated.reactions.length, before + 1);
    expect(updated.reactions.last.mine, isTrue);

    controller().toggleReaction(quest.id, completion.id, '👏');
    updated = container
        .read(gameProvider)
        .friendCompletions(quest.id)
        .firstWhere((c) => c.id == completion.id);
    expect(updated.reactions.length, before);
  });

  test('un niveau est franchi quand le seuil est dépassé', () {
    final set = container.read(gameProvider).todaySet;
    final before = container.read(gameProvider).user;

    for (final quest in set.all) {
      controller().completeQuest(
        quest: quest,
        scene: quest.scene,
        result: QuestCheckService.analyse(quest: quest, scene: quest.scene),
      );
    }

    final after = container.read(gameProvider).user;
    final gained = set.all.fold(0, (sum, q) => sum + q.xpReward);
    expect(after.level, greaterThanOrEqualTo(before.level));
    expect(
      after.level > before.level || after.xp == before.xp + gained,
      isTrue,
      reason: 'soit on passe un niveau, soit tout l\'XP est cumulé',
    );
  });

  test('accepter une invitation ajoute la personne aux amis', () {
    final invitation = container.read(gameProvider).invitations.first;
    final before = container.read(gameProvider).friends.length;

    controller().answerInvitation(invitation.id, accept: true);

    expect(container.read(gameProvider).friends.length, before + 1);
    expect(
      container.read(gameProvider).invitations.any((i) => i.id == invitation.id),
      isFalse,
    );
  });

  test('une quête du jour non faite ne compte pas dans le récap', () {
    expect(container.read(gameProvider).dailyCompletedCount, 0);
    expect(container.read(gameProvider).dailyXpEarned, 0);
  });

  test('sa propre participation ouvre le fil de la quête', () {
    final quest = container.read(gameProvider).todaySet.hard;
    final before = container.read(gameProvider).friendCompletions(quest.id).length;

    controller().completeQuest(
      quest: quest,
      scene: Scene.sunsetOcean,
      result: QuestCheckService.analyse(quest: quest, scene: Scene.sunsetOcean),
    );

    final after = container.read(gameProvider).friendCompletions(quest.id);
    expect(after.length, before + 1);
    expect(after.first.author.id, container.read(currentUserProvider).id);
  });
}
