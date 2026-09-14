import 'dart:typed_data';

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';

/// Contrat entre l'interface et la source de données.
///
/// Deux implémentations : les données mockées du prototype, et Firestore avec
/// les Cloud Functions. Les écrans ne connaissent que ce contrat, ce qui permet
/// de basculer sans les toucher.
abstract interface class QuestRepository {
  /// Identifiant du joueur connecté, ou null.
  String? get currentUserId;

  /// Profil du joueur, mis à jour en continu.
  Stream<AppUser> watchUser();

  /// Set du jour assigné au joueur (§74).
  Stream<DailyQuestSet> watchDailySet();

  /// État des quêtes du joueur : disponible, en cours, terminée.
  Stream<Map<String, QuestProgress>> watchQuestStates();

  /// Participations visibles pour une quête, la sienne comprise (§21).
  Stream<List<QuestCompletion>> watchCompletions(String questId);

  Stream<List<Friend>> watchFriends();
  Stream<List<FriendActivity>> watchActivity();
  Stream<List<FriendChallenge>> watchChallenges();
  Stream<List<FriendInvitation>> watchInvitations();

  /// Quêtes mises en avant dans l'onglet Explorer (§59).
  Future<List<Quest>> trendingQuests();
  Future<List<Quest>> communityQuests();

  /// Signale le démarrage d'une quête (§76).
  Future<void> startQuest(String questId);

  /// Dépose une preuve et crée la participation.
  ///
  /// Rend l'identifiant de la participation : l'appelant observe ensuite son
  /// statut, que seul le serveur fait évoluer (§83).
  Future<String> submitProof({
    required Quest quest,
    required Uint8List imageBytes,
    required DateTime capturedAt,
    String? caption,
  });

  /// Suit le verdict rendu sur une participation.
  Stream<QuestCompletion> watchCompletion(String completionId);

  Future<void> toggleReaction(String questId, String completionId, String emoji);
  Future<void> addComment(String questId, String completionId, String text);

  Future<void> answerChallenge(String challengeId, {required bool accept});
  Future<void> answerInvitation(String invitationId, {required bool accept});
  Future<void> sendChallenge({required Friend to, required String text});

  Future<void> saveInterests(List<QuestCategory> interests);

  /// Demande une nouvelle vérification après un refus (§40).
  Future<void> contest(String completionId);
}

/// Erreur remontée à l'interface avec un message présentable.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
