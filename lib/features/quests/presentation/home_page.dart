import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/loading_screen.dart';
import '../../../shared/widgets/logo.dart';
import '../../../shared/widgets/misc.dart';
import '../../../shared/widgets/quest_card.dart';
import '../domain/game_controller.dart';
import '../domain/game_state.dart';
import '../../../core/l10n/labels.dart';

/// Écran 04 — Quest Board (§27, §183).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final user = game.user;
    final set = game.todaySet;

    if (user == null || set == null) {
      return LoadingScreen(message: game.error);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(game: game, user: user)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  SectionHeader(
                    title: context.l.dailyQuests,
                    action: '${game.dailyCompletedCount}/${set.all.length}',
                  ),
                  for (final quest in set.daily) ...[
                    QuestCard(
                      quest: quest,
                      completed: game.isCompleted(quest.id),
                      onTap: () => _open(context, game, quest),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  WorldQuestCard(
                    quest: set.world,
                    completed: game.isCompleted(set.world.id),
                    onTap: () => _open(context, game, set.world),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (game.dailyCompletedCount > 0) _DailySummary(game: game),
                  const SizedBox(height: AppSpacing.lg),
                  _FriendsToday(game: game),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, GameState game, Quest quest) {
    if (game.isCompleted(quest.id)) {
      context.push('/feed', extra: quest);
    } else {
      context.push('/quest', extra: quest);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.user});

  final GameState game;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              const Crown(size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'QUEST',
                style: AppTypography.label.copyWith(fontSize: 13, letterSpacing: 1.4),
              ),
              const Spacer(),
              const _NotificationBell(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.homeGreeting(user.displayName),
                  style: AppTypography.screenTitle,
                ),
              ),
              UserAvatar(
                seed: user.id,
                name: user.displayName,
                size: 44,
                ring: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.chipR,
                ),
                child: Text(
                  context.l.level(user.level),
                  style: AppTypography.label.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(user.title, style: AppTypography.bodyStrong.copyWith(fontSize: 14)),
              const Spacer(),
              Text(
                context.l.xpProgress(user.xp, user.xpForNextLevel),
                style: AppTypography.metadata,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          XPProgressBar(ratio: user.levelRatio),
          const SizedBox(height: AppSpacing.sm),
          StreakBadge(user.streak),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface1,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: AppColors.textSecondary),
        ),
        Positioned(
          right: 9,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.hard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Récapitulatif de la journée (§131).
class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final total = game.todaySet?.all.length ?? 0;
    final done = game.dailyCompletedCount;
    final complete = done == total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.cardR,
        border: Border.all(
          color: complete ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complete ? context.l.dayComplete : context.l.yourDay,
                style: AppTypography.label.copyWith(
                  color: complete ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                context.l.questCount(done, total),
                style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${game.dailyXpEarned}', style: AppTypography.hero.copyWith(fontSize: 30)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  context.l.xpToday,
                  style: AppTypography.body.copyWith(fontSize: 14),
                ),
              ),
              const Spacer(),
              StreakBadge(game.user?.streak ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

/// Progression des amis : du FOMO sans divulgâcher les réponses (§132).
class _FriendsToday extends StatelessWidget {
  const _FriendsToday({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final total = game.todaySet?.all.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l.friendsToday),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppRadius.cardR,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final friend in game.friends.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      UserAvatar(seed: friend.id, name: friend.displayName, size: 32),
                      const SizedBox(width: AppSpacing.sm),
                      Text(friend.displayName, style: AppTypography.bodyStrong.copyWith(fontSize: 14.5)),
                      const SizedBox(width: AppSpacing.xs),
                      Text('🔥${friend.streak}', style: AppTypography.metadata),
                      const Spacer(),
                      Row(
                        children: [
                          for (var i = 0; i < total; i++)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < friend.questsToday
                                    ? AppColors.success
                                    : AppColors.surface3,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${friend.questsToday}/$total',
                          style: AppTypography.metadata,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
