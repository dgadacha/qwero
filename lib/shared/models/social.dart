import 'package:freezed_annotation/freezed_annotation.dart';

import 'quest.dart';
import 'user.dart';

part 'social.freezed.dart';

enum FriendActivityKind { completed, challenged, invited, levelUp, reacted }

/// Une ligne du fil d'activité des amis (§61).
@freezed
abstract class FriendActivity with _$FriendActivity {
  const factory FriendActivity({
    required String id,
    required Friend friend,
    required FriendActivityKind kind,
    required String text,
    required Duration ago,
    String? highlight,
  }) = _FriendActivity;
}

enum ChallengeState { pending, accepted, completed, declined }

/// Un défi lancé par un ami (§46).
@freezed
abstract class FriendChallenge with _$FriendChallenge {
  const factory FriendChallenge({
    required String id,
    required Friend from,
    required Quest quest,
    required ChallengeState state,
    required Duration timeLeft,
    @Default(false) bool outgoing,
  }) = _FriendChallenge;
}

/// Invitation d'amitié en attente (§60).
@freezed
abstract class FriendInvitation with _$FriendInvitation {
  const factory FriendInvitation({
    required String id,
    required Friend friend,
    required int mutualFriends,
  }) = _FriendInvitation;
}
