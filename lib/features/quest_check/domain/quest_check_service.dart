import 'dart:math' as math;

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/scene.dart';

/// Simulation locale de QuestCheck (§33 à §36).
///
/// En phase 2, cette classe est remplacée par un appel à une Cloud Function :
/// checks déterministes côté serveur, puis analyse multimodale par Claude, et
/// un Score Engine dont les seuils viennent de Remote Config. Le client ne
/// décide jamais du résultat (§8).
abstract final class QuestCheckService {
  static const passThreshold = 0.90;
  static const uncertainThreshold = 0.60;

  /// Les critères « plausibles » par scène, pour que la démo ne valide pas
  /// n'importe quelle photo : cadrer un parking sur une quête coucher de
  /// soleil doit échouer, comme en production.
  static const _sceneTraits = <Scene, Set<String>>{
    Scene.sunsetOcean: {'sunset', 'outdoor', 'sky', 'water'},
    Scene.harbor: {'sunset', 'outdoor', 'water', 'sky'},
    Scene.beachPalms: {'sunset', 'outdoor', 'water', 'sky'},
    Scene.hikeRidge: {'sunset', 'outdoor', 'sky'},
    Scene.citySky: {'sky', 'outdoor'},
    Scene.snowPeak: {'sky', 'outdoor'},
    Scene.desertDunes: {'sky', 'outdoor', 'sunset'},
    Scene.openRoad: {'outdoor', 'new_place', 'sky'},
    Scene.forest: {'outdoor', 'new_place'},
    Scene.skatepark: {'outdoor', 'new_place'},
    Scene.metro: {'new_place'},
    Scene.redCar: {'red', 'outdoor', 'car'},
    Scene.yellowCar: {'yellow', 'outdoor', 'car'},
    Scene.streetFood: {'red', 'outdoor'},
    Scene.sunflower: {'yellow', 'outdoor'},
    Scene.coffee: {'indoor'},
    Scene.loneTree: {'outdoor', 'sky'},
    Scene.puddleReflection: {'outdoor', 'reflection'},
    Scene.windowReflection: {'reflection'},
    Scene.mountainLake: {'outdoor', 'sky', 'water'},
    Scene.kayak: {'outdoor', 'water', 'sky'},
    Scene.fishing: {'outdoor', 'water'},
    Scene.nightCity: {'outdoor', 'sky'},
    Scene.balcony: {'outdoor', 'sunset', 'sky'},
  };

  /// Traduit un critère de quête en trait attendu dans l'image.
  static String? _traitFor(String requirementId) => switch (requirementId) {
    'outdoor' => 'outdoor',
    'sky' => 'sky',
    'color_red' => 'red',
    'color_yellow' => 'yellow',
    'car' => 'car',
    'before_20' || 'sunset' => 'sunset',
    _ => null,
  };

  /// Analyse une capture. [scene] tient lieu de contenu d'image.
  static QuestCheckResult analyse({required Quest quest, required Scene scene}) {
    final traits = _sceneTraits[scene] ?? const <String>{};
    final checks = <QuestCheckItem>[];

    for (final requirement in quest.requirements) {
      final trait = _traitFor(requirement.id);
      // Les contrôles déterministes (capture en direct, horodatage) sont
      // toujours satisfaits : la photo vient de l'app (§34).
      final deterministic = trait == null;
      final passed = deterministic || traits.contains(trait);
      checks.add(
        QuestCheckItem(
          id: requirement.id,
          label: requirement.label,
          passed: passed,
          confidence: deterministic
              ? 1.0
              : passed
                  ? 0.88 + _jitter(scene, requirement.id) * 0.11
                  : 0.1 + _jitter(scene, requirement.id) * 0.25,
        ),
      );
    }

    // Un dernier contrôle systématique, pour le rythme de l'animation.
    // Libellé résolu à l'affichage (voir `checkLabel`) : le domaine ne porte
    // aucune chaîne visible.
    checks.add(const QuestCheckItem(id: 'geo', label: 'geo', passed: true));

    final score = checks.map((c) => c.passed ? c.confidence : 0.0).reduce((a, b) => a + b) /
        checks.length;

    final verdict = switch (score) {
      >= passThreshold => QuestCheckVerdict.pass,
      >= uncertainThreshold => QuestCheckVerdict.uncertain,
      _ => QuestCheckVerdict.fail,
    };

    return QuestCheckResult(
      verdict: verdict,
      score: score,
      checks: checks,
      reason: switch (verdict) {
        QuestCheckVerdict.pass => 'Tous les critères de la quête sont réunis.',
        QuestCheckVerdict.uncertain =>
          "Certains éléments manquent pour valider la quête avec certitude.",
        QuestCheckVerdict.fail =>
          "Cette photo ne montre pas ce que la quête demande.",
      },
    );
  }

  /// Variation stable par couple scène/critère, pour éviter un score qui
  /// change à chaque affichage.
  static double _jitter(Scene scene, String requirementId) {
    final seed = scene.index * 131 + requirementId.hashCode;
    return math.Random(seed).nextDouble();
  }
}
