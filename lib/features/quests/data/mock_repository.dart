import 'dart:async';
import 'dart:typed_data';

import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/scene.dart';
import '../../quest_check/domain/quest_check_service.dart';
import 'mock_data.dart';
import 'quest_repository.dart';

/// Source de données du prototype (§125).
///
/// Tout est en mémoire : l'application reste jouable hors-ligne et sans projet
/// Firebase. La validation est simulée localement, ce que le serveur fera en
/// production.
class MockRepository implements QuestRepository {
  MockRepository() {
    _user = MockData.me;
    _friends = MockData.friends;
    _challenges = MockData.challenges;
    _invitations = MockData.invitations;
    _activity = MockData.activity;
    for (final quest in MockData.todaySet.all) {
      _completions[quest.id] = MockData.completionsFor(quest.id);
    }
  }

  late AppUser _user;
  late List<Friend> _friends;
  late List<FriendChallenge> _challenges;
  late List<FriendInvitation> _invitations;
  late List<FriendActivity> _activity;

  final _questStates = <String, QuestProgress>{};
  final _completions = <String, List<QuestCompletion>>{};

  final _userController = StreamController<AppUser>.broadcast();
  final _statesController = StreamController<Map<String, QuestProgress>>.broadcast();
  final _friendsController = StreamController<List<Friend>>.broadcast();
  final _challengesController = StreamController<List<FriendChallenge>>.broadcast();
  final _invitationsController = StreamController<List<FriendInvitation>>.broadcast();
  final _completionControllers = <String, StreamController<List<QuestCompletion>>>{};
  final _singleCompletion = <String, StreamController<QuestCompletion>>{};

  /// Scène capturée, transmise par la caméra simulée du prototype.
  Scene pendingScene = Scene.sunsetOcean;

  @override
  String? get currentUserId => MockData.me.id;

  @override
  Stream<AppUser> watchUser() =>
      _userController.stream.asBroadcastStream()..listen(null);

  @override
  Stream<DailyQuestSet> watchDailySet() => Stream.value(MockData.todaySet);

  @override
  Stream<Map<String, QuestProgress>> watchQuestStates() => _statesController.stream;

  @override
  Stream<List<QuestCompletion>> watchCompletions(String questId) {
    final controller = _completionControllers.putIfAbsent(
      questId,
      () => StreamController<List<QuestCompletion>>.broadcast(
        onListen: () => _emitCompletions(questId),
      ),
    );
    return controller.stream;
  }

  @override
  Stream<QuestCompletion> watchCompletion(String completionId) {
    return _singleCompletion
        .putIfAbsent(completionId, StreamController<QuestCompletion>.broadcast)
        .stream;
  }

  @override
  Stream<List<Friend>> watchFriends() => _friendsController.stream;

  @override
  Stream<List<FriendActivity>> watchActivity() => Stream.value(_activity);

  @override
  Stream<List<FriendChallenge>> watchChallenges() => _challengesController.stream;

  @override
  Stream<List<FriendInvitation>> watchInvitations() => _invitationsController.stream;

  @override
  Future<List<Quest>> trendingQuests() async => MockData.trending;

  @override
  Future<List<Quest>> communityQuests() async => MockData.community;

  @override
  Future<void> startQuest(String questId) async {
    _questStates[questId] = QuestProgress.inProgress;
    _statesController.add(Map.of(_questStates));
  }

  @override
  Future<String> submitProof({
    required Quest quest,
    required Uint8List imageBytes,
    required DateTime capturedAt,
    String? caption,
  }) async {
    final completionId = 'c_me_${quest.id}';
    final result = QuestCheckService.analyse(quest: quest, scene: pendingScene);

    final completion = QuestCompletion(
      id: completionId,
      questId: quest.id,
      author: MockData.dylan,
      scene: pendingScene,
      status: switch (result.verdict) {
        QuestCheckVerdict.pass => CompletionStatus.validated,
        QuestCheckVerdict.uncertain => CompletionStatus.uncertain,
        QuestCheckVerdict.fail => CompletionStatus.rejected,
      },
      xpAwarded: result.verdict == QuestCheckVerdict.pass ? quest.xpReward : 0,
      validationScore: result.score,
      caption: caption,
      ago: Duration.zero,
      checks: result.checks,
    );

    if (result.verdict == QuestCheckVerdict.pass) {
      _applyReward(quest);
      _questStates[quest.id] = QuestProgress.completed;
      _statesController.add(Map.of(_questStates));
      _completions[quest.id] = [completion, ...?_completions[quest.id]];
      _emitCompletions(quest.id);
    }

    _singleCompletion
        .putIfAbsent(completionId, StreamController<QuestCompletion>.broadcast)
        .add(completion);

    return completionId;
  }

  void _applyReward(Quest quest) {
    var xp = _user.xp + quest.xpReward;
    var level = _user.level;
    while (xp >= AppUser.xpForLevel(level)) {
      xp -= AppUser.xpForLevel(level);
      level += 1;
    }

    final firstOfDay = _questStates.values
        .where((state) => state == QuestProgress.completed)
        .isEmpty;

    _user = _user.copyWith(
      xp: xp,
      level: level,
      questsCompleted: _user.questsCompleted + 1,
      streak: firstOfDay ? _user.streak + 1 : _user.streak,
    );
    _userController.add(_user);
  }

  @override
  Future<void> toggleReaction(String questId, String completionId, String emoji) async {
    final list = _completions[questId] ?? const <QuestCompletion>[];
    _completions[questId] = [
      for (final completion in list)
        if (completion.id != completionId)
          completion
        else
          completion.copyWith(reactions: _toggled(completion.reactions, emoji)),
    ];
    _emitCompletions(questId);
  }

  List<Reaction> _toggled(List<Reaction> reactions, String emoji) {
    final index = reactions.indexWhere((r) => r.emoji == emoji);
    if (index == -1) return [...reactions, Reaction(emoji: emoji, count: 1, mine: true)];

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

  @override
  Future<void> addComment(String questId, String completionId, String text) async {
    final list = _completions[questId] ?? const <QuestCompletion>[];
    _completions[questId] = [
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
    _emitCompletions(questId);
  }

  @override
  Future<void> answerChallenge(String challengeId, {required bool accept}) async {
    _challenges = [
      for (final challenge in _challenges)
        if (challenge.id != challengeId)
          challenge
        else
          challenge.copyWith(
            state: accept ? ChallengeState.accepted : ChallengeState.declined,
          ),
    ];
    _challengesController.add(_challenges);
  }

  @override
  Future<void> answerInvitation(String invitationId, {required bool accept}) async {
    final invitation = _invitations.firstWhere((i) => i.id == invitationId);
    _invitations = _invitations.where((i) => i.id != invitationId).toList();
    if (accept) {
      _friends = [..._friends, invitation.friend];
      _friendsController.add(_friends);
    }
    _invitationsController.add(_invitations);
  }

  @override
  Future<void> sendChallenge({required Friend to, required String text}) async {
    _challenges = [
      FriendChallenge(
        id: 'ch_${DateTime.now().microsecondsSinceEpoch}',
        from: to,
        quest: Quest(
          id: 'q_user_${DateTime.now().microsecondsSinceEpoch}',
          title: text,
          description: 'Challenge lancé par toi.',
          category: QuestCategory.funny,
          difficulty: QuestDifficulty.medium,
          xpReward: 150,
          estimatedMinutes: 20,
          scene: Scene.nightCity,
        ),
        state: ChallengeState.pending,
        timeLeft: const Duration(hours: 24),
        outgoing: true,
      ),
      ..._challenges,
    ];
    _challengesController.add(_challenges);
  }

  @override
  Future<void> saveInterests(List<QuestCategory> interests) async {
    _user = _user.copyWith(interests: interests);
    _userController.add(_user);
  }

  @override
  Future<void> contest(String completionId) async {}

  void _emitCompletions(String questId) {
    _completionControllers[questId]?.add(_completions[questId] ?? const []);
  }

  /// Valeurs immédiates, pour le premier rendu sans attente.
  AppUser get user => _user;
  List<Friend> get friends => _friends;
  List<FriendChallenge> get challenges => _challenges;
  List<FriendInvitation> get invitations => _invitations;
  List<FriendActivity> get activity => _activity;
  Map<String, QuestProgress> get questStates => Map.of(_questStates);
  List<QuestCompletion> completionsOf(String questId) => _completions[questId] ?? const [];
}
