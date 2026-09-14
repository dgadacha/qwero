import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/social.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/misc.dart';
import '../../quests/domain/game_controller.dart';
import 'create_sheet.dart';
import '../../../core/l10n/labels.dart';

/// Écran 13 — Amis (§60, §192). Des événements compacts, pas un feed photo.
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(context.l.friendsTitle, style: AppTypography.screenTitle),
                      const Spacer(),
                      GlassIconButton(
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: () => context.push('/add-friends'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedTabs(
                    tabs: [
                      context.l.tabActivity,
                      context.l.tabChallenges,
                      context.l.tabInvitations,
                    ],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                    badges: {
                      1: game.pendingChallenges,
                      2: game.invitations.length,
                    }..removeWhere((_, value) => value == 0),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => const _ActivityTab(),
                1 => const _ChallengesTab(),
                _ => const _InvitationsTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(gameProvider).activity;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, 110),
      itemCount: activity.length + 1,
      itemBuilder: (context, i) {
        if (i == activity.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: EmptyState(
              emoji: '✨',
              title: context.l.upToDate,
              message: context.l.upToDateBody,
            ),
          );
        }
        return _ActivityRow(item: activity[i]);
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final FriendActivity item;

  IconData get _icon => switch (item.kind) {
    FriendActivityKind.completed => Icons.check_circle_rounded,
    FriendActivityKind.challenged => Icons.sports_kabaddi_rounded,
    FriendActivityKind.invited => Icons.group_add_rounded,
    FriendActivityKind.levelUp => Icons.trending_up_rounded,
    FriendActivityKind.reacted => Icons.favorite_rounded,
  };

  Color get _color => switch (item.kind) {
    FriendActivityKind.completed => AppColors.success,
    FriendActivityKind.challenged => AppColors.hard,
    FriendActivityKind.invited => AppColors.primaryLight,
    FriendActivityKind.levelUp => AppColors.xp,
    FriendActivityKind.reacted => AppColors.hard,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(seed: item.friend.id, name: item.friend.displayName, size: 42),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 12, color: _color),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.body.copyWith(fontSize: 14.5),
                    children: [
                      TextSpan(
                        text: item.friend.displayName,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14.5),
                      ),
                      TextSpan(text: ' ${item.text}'),
                    ],
                  ),
                ),
                if (item.highlight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.highlight!,
                    style: AppTypography.bodyStrong.copyWith(
                      fontSize: 13.5,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(formatAgo(context.l, item.ago), style: AppTypography.metadata),
              ],
            ),
          ),
          if (item.kind == FriendActivityKind.challenged ||
              item.kind == FriendActivityKind.invited)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(gameProvider).challenges;

    if (challenges.isEmpty) {
      return EmptyState(
        emoji: '⚔️',
        title: context.l.noChallenge,
        message: context.l.noChallengeBody,
        actionLabel: context.l.sendChallenge,
        onAction: () => showCreateSheet(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, 110),
      itemCount: challenges.length,
      itemBuilder: (context, i) => _ChallengeCard(challenge: challenges[i]),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final FriendChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = challenge.quest;
    final pending = challenge.state == ChallengeState.pending && !challenge.outgoing;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.cardR,
        border: Border.all(
          color: pending ? AppColors.hard.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SceneImage(quest.scene, scrim: true),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: AppRadius.chipR,
                            ),
                            child: Text(
                              challenge.outgoing
                                  ? '⚔️ ${context.l.youChallenged(challenge.from.displayName.toUpperCase())}'
                                  : '⚔️ ${context.l.challengedYou(challenge.from.displayName.toUpperCase())}',
                              style: AppTypography.label.copyWith(fontSize: 9.5),
                            ),
                          ),
                          const Spacer(),
                          XPBadge(quest.xpReward, compact: true),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        quest.title.toUpperCase(),
                        style: AppTypography.questTitle.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  challenge.state == ChallengeState.completed
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 15,
                  color: challenge.state == ChallengeState.completed
                      ? AppColors.success
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 5),
                Text(
                  switch (challenge.state) {
                    ChallengeState.completed => context.l.challengeDone,
                    ChallengeState.declined => context.l.challengeDeclined,
                    _ => context.l.timeLeftHours(challenge.timeLeft.inHours),
                  },
                  style: AppTypography.metadata,
                ),
                const Spacer(),
                if (pending) ...[
                  SecondaryButton(
                    label: context.l.decline,
                    expanded: false,
                    height: 38,
                    onPressed: () => ref
                        .read(gameProvider.notifier)
                        .answerChallenge(challenge.id, accept: false),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PrimaryButton(
                    label: context.l.accept,
                    expanded: false,
                    height: 38,
                    onPressed: () {
                      ref
                          .read(gameProvider.notifier)
                          .answerChallenge(challenge.id, accept: true);
                      context.push('/quest', extra: quest);
                    },
                  ),
                ] else if (challenge.state == ChallengeState.accepted)
                  PrimaryButton(
                    label: context.l.doTheQuest,
                    expanded: false,
                    height: 38,
                    onPressed: () => context.push('/quest', extra: quest),
                  )
                else if (challenge.state == ChallengeState.completed)
                  SecondaryButton(
                    label: context.l.seeDuel,
                    expanded: false,
                    height: 38,
                    onPressed: () => context.push('/feed', extra: quest),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationsTab extends ConsumerWidget {
  const _InvitationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(gameProvider).invitations;

    if (invitations.isEmpty) {
      return EmptyState(
        emoji: '📬',
        title: context.l.noInvitation,
        message: context.l.noInvitationBody,
        actionLabel: context.l.addFriends,
        onAction: () => context.push('/add-friends'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, 110),
      itemCount: invitations.length,
      itemBuilder: (context, i) {
        final invitation = invitations[i];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppRadius.cardR,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              UserAvatar(
                seed: invitation.friend.id,
                name: invitation.friend.displayName,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invitation.friend.displayName, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      context.l.mutualFriends(invitation.mutualFriends),
                      style: AppTypography.metadata,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(gameProvider.notifier)
                    .answerInvitation(invitation.id, accept: false),
                icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
              ),
              PrimaryButton(
                label: context.l.accept,
                expanded: false,
                height: 38,
                onPressed: () => ref
                    .read(gameProvider.notifier)
                    .answerInvitation(invitation.id, accept: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
