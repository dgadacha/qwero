import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/scene.dart';

/// Conversion des documents Firestore vers les modèles de l'application.
///
/// Les documents viennent du serveur et peuvent contenir des champs absents ou
/// d'un type inattendu : chaque lecture retombe sur une valeur sûre plutôt que
/// de faire échouer l'écran.
abstract final class Mappers {
  static QuestDifficulty difficulty(String? raw) => switch (raw) {
    'easy' => QuestDifficulty.easy,
    'medium' => QuestDifficulty.medium,
    'hard' => QuestDifficulty.hard,
    'world' => QuestDifficulty.world,
    _ => QuestDifficulty.easy,
  };

  static QuestCategory category(String? raw) =>
      QuestCategory.values.firstWhere(
        (category) => category.name == raw,
        orElse: () => QuestCategory.observation,
      );

  static CompletionStatus status(String? raw) => switch (raw) {
    'validated' => CompletionStatus.validated,
    'uncertain' => CompletionStatus.uncertain,
    'rejected' => CompletionStatus.rejected,
    'delayed' => CompletionStatus.analyzing,
    _ => CompletionStatus.analyzing,
  };

  /// En attendant les vraies photos, la scène est dérivée de l'identifiant :
  /// deux participations différentes ne se ressemblent pas, et le rendu reste
  /// stable d'un affichage à l'autre.
  static Scene sceneFor(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return Scene.values[hash % Scene.values.length];
  }

  static Quest quest(String id, Map<String, dynamic> data) {
    final requirements = (data['requirements'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((r) => r['type'] != 'technical')
        .map(
          (r) => QuestRequirement(
            id: r['id'] as String? ?? 'requirement',
            label: r['label'] as String? ?? '',
            emoji: r['emoji'] as String? ?? '•',
          ),
        )
        .toList();

    return Quest(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: category(data['category'] as String?),
      difficulty: difficulty(data['difficulty'] as String?),
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt() ?? 5,
      scene: sceneFor(id),
      requirements: [
        const QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
        ...requirements,
      ],
      participantCount: (data['usageCount'] as num?)?.toInt() ?? 0,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      worldNumber: data['worldNumber'] as String?,
    );
  }

  static AppUser user(String id, Map<String, dynamic> data) => AppUser(
    id: id,
    username: data['username'] as String? ?? '',
    displayName: data['displayName'] as String? ?? '',
    level: (data['level'] as num?)?.toInt() ?? 1,
    xp: (data['xp'] as num?)?.toInt() ?? 0,
    streak: (data['streak'] as num?)?.toInt() ?? 0,
    questsCompleted: (data['questsCompleted'] as num?)?.toInt() ?? 0,
    interests: (data['interests'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((name) => category(name))
        .toList(),
    timezone: data['timezone'] as String? ?? 'Europe/Paris',
  );

  static Friend friend(String id, Map<String, dynamic> data) => Friend(
    id: id,
    username: data['username'] as String? ?? '',
    displayName: data['displayName'] as String? ?? '',
    level: (data['level'] as num?)?.toInt() ?? 1,
    streak: (data['streak'] as num?)?.toInt() ?? 0,
    questsToday: (data['questsToday'] as num?)?.toInt() ?? 0,
  );

  static QuestCheckItem check(Map<String, dynamic> data) => QuestCheckItem(
    id: data['id'] as String? ?? '',
    label: data['label'] as String? ?? '',
    passed: data['passed'] as bool? ?? false,
    confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
  );

  static QuestCompletion completion(
    String id,
    Map<String, dynamic> data,
    Friend author,
    List<Reaction> reactions,
  ) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    return QuestCompletion(
      id: id,
      questId: data['questId'] as String? ?? '',
      author: author,
      scene: sceneFor(id),
      status: status(data['status'] as String?),
      xpAwarded: (data['xpAwarded'] as num?)?.toInt() ?? 0,
      validationScore: (data['validationScore'] as num?)?.toDouble() ?? 0,
      checks: (data['checks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(check)
          .toList(),
      caption: data['caption'] as String?,
      ago: createdAt == null ? Duration.zero : DateTime.now().difference(createdAt),
      reactions: reactions,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      visibility: switch (data['visibility'] as String?) {
        'private' => QuestVisibility.private,
        'public' => QuestVisibility.public,
        _ => QuestVisibility.friends,
      },
    );
  }

  static ChallengeState challengeState(String? raw) => switch (raw) {
    'accepted' => ChallengeState.accepted,
    'completed' => ChallengeState.completed,
    'declined' || 'expired' => ChallengeState.declined,
    _ => ChallengeState.pending,
  };

  static QuestProgress progress(String? raw) => switch (raw) {
    'in_progress' => QuestProgress.inProgress,
    'completed' => QuestProgress.completed,
    'expired' => QuestProgress.expired,
    _ => QuestProgress.available,
  };
}
