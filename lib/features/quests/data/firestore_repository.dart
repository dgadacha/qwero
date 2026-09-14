import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/backend/firebase_init.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';
import 'firestore_mappers.dart';
import 'quest_repository.dart';

/// Source de données réelle : Firestore en lecture, Cloud Functions en écriture.
///
/// Toute écriture qui décide d'une récompense passe par une fonction (§8). Le
/// client se contente de déposer sa preuve et d'observer le verdict arriver.
class FirestoreRepository implements QuestRepository {
  FirestoreRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: FirebaseInit.region);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  /// Profils déjà lus, pour ne pas recharger l'auteur à chaque participation.
  final _profiles = <String, Friend>{};

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  String get _uid {
    final uid = currentUserId;
    if (uid == null) throw const RepositoryException('Session expirée.');
    return uid;
  }

  // ------------------------------------------------------------- lectures

  @override
  Stream<AppUser> watchUser() => _db
      .collection('users')
      .doc(_uid)
      .snapshots()
      .where((snapshot) => snapshot.exists)
      .map((snapshot) => Mappers.user(snapshot.id, snapshot.data()!));

  @override
  Stream<DailyQuestSet> watchDailySet() {
    // Les assignations font foi : c'est le serveur qui décide des quêtes du
    // jour, le client ne compose rien (§74).
    return _db
        .collection('users')
        .doc(_uid)
        .collection('assignments')
        .where('status', whereNotIn: ['expired'])
        .snapshots()
        .asyncMap((snapshot) async {
      final byDifficulty = <String, String>{};
      String? setId;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        byDifficulty[data['difficulty'] as String? ?? 'easy'] =
            data['questId'] as String? ?? doc.id;
        setId ??= data['dailySetId'] as String?;
      }

      final quests = await Future.wait(
        ['easy', 'medium', 'hard', 'world'].map((difficulty) async {
          final questId = byDifficulty[difficulty];
          if (questId == null) return null;
          final doc = await _db.collection('questTemplates').doc(questId).get();
          if (!doc.exists) return null;
          return Mappers.quest(doc.id, doc.data()!);
        }),
      );

      if (quests.any((quest) => quest == null)) {
        throw const RepositoryException("Les quêtes du jour ne sont pas encore prêtes.");
      }

      return DailyQuestSet(
        id: setId ?? 'today',
        date: DateTime.now(),
        easy: quests[0]!,
        medium: quests[1]!,
        hard: quests[2]!,
        world: quests[3]!,
      );
    });
  }

  @override
  Stream<Map<String, QuestProgress>> watchQuestStates() => _db
      .collection('users')
      .doc(_uid)
      .collection('assignments')
      .snapshots()
      .map((snapshot) => {
            for (final doc in snapshot.docs)
              (doc.data()['questId'] as String? ?? doc.id):
                  Mappers.progress(doc.data()['status'] as String?),
          });

  @override
  Stream<List<QuestCompletion>> watchCompletions(String questId) => _db
      .collection('questCompletions')
      .where('questId', isEqualTo: questId)
      .where('status', isEqualTo: 'validated')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .asyncMap((snapshot) async {
        final completions = <QuestCompletion>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final authorId = data['userId'] as String? ?? '';
          final author = await _profileOf(authorId);
          final reactions = await _reactionsOf(doc.reference);
          completions.add(Mappers.completion(doc.id, data, author, reactions));
        }
        // Sa propre participation ouvre le fil.
        completions.sort((a, b) {
          if (a.author.id == _uid) return -1;
          if (b.author.id == _uid) return 1;
          return a.ago.compareTo(b.ago);
        });
        return completions;
      });

  @override
  Stream<QuestCompletion> watchCompletion(String completionId) => _db
      .collection('questCompletions')
      .doc(completionId)
      .snapshots()
      .where((snapshot) => snapshot.exists)
      .asyncMap((snapshot) async {
        final data = snapshot.data()!;
        final author = await _profileOf(data['userId'] as String? ?? '');
        return Mappers.completion(snapshot.id, data, author, const []);
      });

  @override
  Stream<List<Friend>> watchFriends() => _db
      .collection('friendships')
      .where('userId', isEqualTo: _uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final friends = await Future.wait(
          snapshot.docs.map((doc) => _profileOf(doc.data()['friendId'] as String? ?? '')),
        );
        return friends.where((friend) => friend.id.isNotEmpty).toList();
      });

  @override
  Stream<List<FriendActivity>> watchActivity() => _db
      .collection('users')
      .doc(_uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .asyncMap((snapshot) async {
        final activity = <FriendActivity>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final actorId = data['actorId'] as String?;
          if (actorId == null) continue;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          activity.add(
            FriendActivity(
              id: doc.id,
              friend: await _profileOf(actorId),
              kind: switch (data['type'] as String?) {
                'challenge_received' => FriendActivityKind.challenged,
                'friend_favorite' => FriendActivityKind.reacted,
                'friend_completed' => FriendActivityKind.completed,
                _ => FriendActivityKind.completed,
              },
              text: data['body'] as String? ?? '',
              ago: createdAt == null ? Duration.zero : DateTime.now().difference(createdAt),
            ),
          );
        }
        return activity;
      });

  @override
  Stream<List<FriendChallenge>> watchChallenges() => _db
      .collection('challenges')
      .where('toId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .asyncMap((snapshot) async {
        final challenges = <FriendChallenge>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final questDoc =
              await _db.collection('questTemplates').doc(data['questId'] as String? ?? '').get();
          if (!questDoc.exists) continue;

          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
          challenges.add(
            FriendChallenge(
              id: doc.id,
              from: await _profileOf(data['fromId'] as String? ?? ''),
              quest: Mappers.quest(questDoc.id, questDoc.data()!),
              state: Mappers.challengeState(data['state'] as String?),
              timeLeft: expiresAt == null
                  ? Duration.zero
                  : expiresAt.difference(DateTime.now()).isNegative
                      ? Duration.zero
                      : expiresAt.difference(DateTime.now()),
            ),
          );
        }
        return challenges;
      });

  @override
  Stream<List<FriendInvitation>> watchInvitations() => _db
      .collection('friendRequests')
      .where('toId', isEqualTo: _uid)
      .where('state', isEqualTo: 'pending')
      .snapshots()
      .asyncMap((snapshot) async {
        final invitations = <FriendInvitation>[];
        for (final doc in snapshot.docs) {
          invitations.add(
            FriendInvitation(
              id: doc.id,
              friend: await _profileOf(doc.data()['fromId'] as String? ?? ''),
              mutualFriends: 0,
            ),
          );
        }
        return invitations;
      });

  @override
  Future<List<Quest>> trendingQuests() async {
    final snapshot = await _db
        .collection('questTemplates')
        .where('status', isEqualTo: 'approved')
        .orderBy('usageCount', descending: true)
        .limit(8)
        .get();
    return snapshot.docs.map((doc) => Mappers.quest(doc.id, doc.data())).toList();
  }

  @override
  Future<List<Quest>> communityQuests() async {
    final snapshot = await _db
        .collection('questTemplates')
        .where('status', isEqualTo: 'approved')
        .where('source', isEqualTo: 'user')
        .limit(8)
        .get();
    return snapshot.docs.map((doc) => Mappers.quest(doc.id, doc.data())).toList();
  }

  // ------------------------------------------------------------ écritures

  @override
  Future<void> startQuest(String questId) =>
      _call('startQuest', {'questId': questId});

  @override
  Future<String> submitProof({
    required Quest quest,
    required Uint8List imageBytes,
    required DateTime capturedAt,
    String? caption,
  }) async {
    final completionRef = _db.collection('questCompletions').doc();
    final proofPath = 'completions/$_uid/${completionRef.id}';

    await _storage.ref(proofPath).putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'questId': quest.id},
          ),
        );

    // Le document est créé en attente : le déclencheur serveur prend le relais
    // et c'est lui, et lui seul, qui écrira le statut et l'XP (§83).
    await completionRef.set({
      'userId': _uid,
      'questId': quest.id,
      'dailySetId': null,
      'challengeId': null,
      'proofPath': proofPath,
      'proofHash': null,
      'status': 'pending_validation',
      'validationScore': 0,
      'xpAwarded': 0,
      'checks': <Map<String, dynamic>>[],
      'reason': null,
      'caption': caption,
      'visibility': 'friends',
      'reactionCount': 0,
      'commentCount': 0,
      'retryCount': 0,
      'contested': false,
      'capturedAt': Timestamp.fromDate(capturedAt),
      'createdAt': FieldValue.serverTimestamp(),
      'validatedAt': null,
    });

    return completionRef.id;
  }

  @override
  Future<void> toggleReaction(String questId, String completionId, String emoji) =>
      _call('toggleReaction', {'completionId': completionId, 'emoji': emoji});

  @override
  Future<void> addComment(String questId, String completionId, String text) =>
      _call('addComment', {'completionId': completionId, 'text': text});

  @override
  Future<void> answerChallenge(String challengeId, {required bool accept}) =>
      _call('answerChallenge', {'challengeId': challengeId, 'accept': accept});

  @override
  Future<void> answerInvitation(String invitationId, {required bool accept}) =>
      _call('answerFriendRequest', {'requestId': invitationId, 'accept': accept});

  @override
  Future<void> sendChallenge({required Friend to, required String text}) =>
      _call('sendChallenge', {'toId': to.id, 'text': text});

  @override
  Future<void> saveInterests(List<QuestCategory> interests) async {
    await _db.collection('users').doc(_uid).update({
      'interests': interests.map((category) => category.name).toList(),
    });
  }

  @override
  Future<void> contest(String completionId) =>
      _call('contestCompletion', {'completionId': completionId});

  // ------------------------------------------------------------ interne

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call<void>(data);
    } on FirebaseFunctionsException catch (error) {
      // Le message vient du serveur et est déjà rédigé pour le joueur.
      throw RepositoryException(error.message ?? 'Une erreur est survenue.');
    }
  }

  Future<List<Reaction>> _reactionsOf(DocumentReference<Map<String, dynamic>> ref) async {
    final snapshot = await ref.collection('reactions').get();
    final counts = <String, int>{};
    final mine = <String>{};

    for (final doc in snapshot.docs) {
      final emoji = doc.data()['emoji'] as String? ?? '';
      if (emoji.isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      if (doc.data()['userId'] == _uid) mine.add(emoji);
    }

    return counts.entries
        .map((entry) => Reaction(
              emoji: entry.key,
              count: entry.value,
              mine: mine.contains(entry.key),
            ))
        .toList();
  }

  Future<Friend> _profileOf(String userId) async {
    if (userId.isEmpty) {
      return const Friend(id: '', username: '', displayName: '?', level: 1);
    }
    final cached = _profiles[userId];
    if (cached != null) return cached;

    final doc = await _db.collection('publicProfiles').doc(userId).get();
    final friend = doc.exists
        ? Mappers.friend(doc.id, doc.data()!)
        : Friend(id: userId, username: '', displayName: '?', level: 1);
    _profiles[userId] = friend;
    return friend;
  }
}
