import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../domain/game_controller.dart';
import '../domain/game_state.dart';
import '../../../core/l10n/labels.dart';

/// Écran 05 — détail d'une quête (§29, §186).
class QuestDetailPage extends ConsumerWidget {
  const QuestDetailPage({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final friendsDone = game.friendCompletions(quest.id).map((c) => c.author.id).toSet();

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SceneImage(quest.scene, scrim: true),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x99080C14),
                              Color(0x00080C14),
                              Color(0x00080C14),
                              Color(0xFF080C14),
                            ],
                            stops: [0.0, 0.38, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            QuestDifficultyBadge(quest.difficulty),
                            const Spacer(),
                            XPBadge(quest.xpReward, compact: false),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          quest.title.toUpperCase(),
                          style: AppTypography.hero.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(quest.description, style: AppTypography.body),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final requirement in quest.requirements)
                              QuestRequirementChip(
                                emoji: requirement.emoji,
                                label: requirementLabel(
                                  context.l,
                                  requirement.id,
                                  requirement.label,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (quest.expiresAt != null) _Countdown(expiresAt: quest.expiresAt!),
                        const SizedBox(height: AppSpacing.md),
                        _Participants(count: quest.participantCount),
                        const SizedBox(height: AppSpacing.lg),
                        if (friendsDone.isNotEmpty) ...[
                          _LockedResults(
                            quest: quest,
                            friendIds: friendsDone,
                            game: game,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  GlassIconButton(
                    icon: Icons.more_horiz_rounded,
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00080C14), Color(0xE6080C14), Color(0xFF080C14)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.xl,
                    AppSpacing.screenH,
                    AppSpacing.xs,
                  ),
                  child: PrimaryButton(
                    label: context.l.startQuest,
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      ref.read(gameProvider.notifier).startQuest(quest.id);
                      context.push('/camera', extra: quest);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded, color: AppColors.textSecondary),
              title: Text(context.l.shareQuest, style: AppTypography.bodyStrong),
              onTap: () => context.pop(),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
              title: Text(context.l.report, style: AppTypography.bodyStrong),
              onTap: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Compte à rebours avant expiration (§29).
class _Countdown extends StatefulWidget {
  const _Countdown({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.expiresAt.difference(DateTime.now());
    final expired = left.isNegative;
    final text = expired
        ? context.l.questOverForToday
        : context.l.endsIn(
            left.inHours,
            (left.inMinutes % 60).toString().padLeft(2, '0'),
          );

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 16,
          color: expired ? AppColors.hard : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.bodyStrong.copyWith(
            fontSize: 14,
            color: expired ? AppColors.hard : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          height: 28,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: i * 20.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.background, width: 2),
                      ),
                    ),
                    child: UserAvatar(
                      seed: 'crowd_$i',
                      name: const ['A', 'M', 'K'][i],
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          context.l.peopleDidIt(_grouped(count)),
          style: AppTypography.metadata.copyWith(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  String _grouped(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

/// Résultats masqués tant que l'utilisateur n'a pas participé (§22).
class _LockedResults extends StatelessWidget {
  const _LockedResults({
    required this.quest,
    required this.friendIds,
    required this.game,
  });

  final Quest quest;
  final Set<String> friendIds;
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                context.l.resultsHidden,
                style: AppTypography.label.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l.completeToReveal,
            style: AppTypography.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final friend in game.friends.where((f) => friendIds.contains(f.id)))
            FriendProgressRow(friend: friend, done: true),
          for (final friend in game.friends.where((f) => !friendIds.contains(f.id)).take(2))
            FriendProgressRow(friend: friend, done: false),
        ],
      ),
    );
  }
}
