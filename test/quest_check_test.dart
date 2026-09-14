import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/quest_check/domain/quest_check_service.dart';
import 'package:quest/features/quests/data/mock_data.dart';
import 'package:quest/shared/models/enums.dart';
import 'package:quest/shared/photos/scene.dart';

void main() {
  group('QuestCheck', () {
    test('valide une photo qui remplit les critères de la quête', () {
      final result = QuestCheckService.analyse(
        quest: MockData.hard,
        scene: Scene.sunsetOcean,
      );

      expect(result.verdict, QuestCheckVerdict.pass);
      expect(result.score, greaterThanOrEqualTo(QuestCheckService.passThreshold));
      expect(result.checks.every((c) => c.passed), isTrue);
    });

    test('refuse une photo qui ne montre pas ce que la quête demande', () {
      final result = QuestCheckService.analyse(
        quest: MockData.hard,
        scene: Scene.coffee,
      );

      expect(result.verdict, isNot(QuestCheckVerdict.pass));
      expect(result.checks.where((c) => !c.passed), isNotEmpty);
    });

    test('les contrôles déterministes passent toujours', () {
      final result = QuestCheckService.analyse(
        quest: MockData.easy,
        scene: Scene.metro,
      );

      final live = result.checks.firstWhere((c) => c.id == 'live');
      expect(live.passed, isTrue);
      expect(live.confidence, 1.0);
    });

    test('le score reste stable entre deux analyses identiques', () {
      final first = QuestCheckService.analyse(quest: MockData.medium, scene: Scene.openRoad);
      final second = QuestCheckService.analyse(quest: MockData.medium, scene: Scene.openRoad);

      expect(first.score, second.score);
    });
  });
}
