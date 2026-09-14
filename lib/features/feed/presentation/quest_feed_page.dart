import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../../../shared/widgets/misc.dart';
import '../../quests/domain/game_controller.dart';
import '../../../core/l10n/labels.dart';

/// Écran 11 — le feed est organisé par quête, jamais par utilisateur (§21).
class QuestFeedPage extends ConsumerStatefulWidget {
  const QuestFeedPage({super.key, required this.quest});

  final Quest quest;

  @override
  ConsumerState<QuestFeedPage> createState() => _QuestFeedPageState();
}

class _QuestFeedPageState extends ConsumerState<QuestFeedPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final unlocked = game.isCompleted(widget.quest.id);
    final completions = game.friendCompletions(widget.quest.id);
    // La cascade se lie au ternaire entier : sans parenthèses, le tri
    // s'appliquerait aussi à l'onglet « Amis » et muterait la liste de l'état.
    final visible = _tab == 0
        ? completions
        : ([...completions]..sort((a, b) => b.reactionCount.compareTo(a.reactionCount)));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quest.title.toUpperCase(),
              style: AppTypography.cardTitle.copyWith(fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              context.l.participations('${completions.length}'),
              style: AppTypography.metadata,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: QuestDifficultyBadge(widget.quest.difficulty, compact: true)),
          ),
        ],
      ),
      body: unlocked
          ? _UnlockedFeed(
              quest: widget.quest,
              completions: visible,
              tab: _tab,
              onTab: (i) => setState(() => _tab = i),
            )
          : _LockedFeed(quest: widget.quest, completions: completions),
    );
  }
}

/// Avant participation : on montre qui a joué, pas ce qu'ils ont trouvé (§22).
class _LockedFeed extends ConsumerWidget {
  const _LockedFeed({required this.quest, required this.completions});

  final Quest quest;
  final List<QuestCompletion> completions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final done = completions.map((c) => c.author.id).toSet();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(context.l.resultsHiddenTitle, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l.doQuestToReveal,
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                      for (final friend in game.friends)
                        FriendProgressRow(friend: friend, done: done.contains(friend.id)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            0,
            AppSpacing.screenH,
            AppSpacing.lg,
          ),
          child: PrimaryButton(
            label: context.l.doTheQuest,
            icon: Icons.camera_alt_rounded,
            onPressed: () => context.pushReplacement('/camera', extra: quest),
          ),
        ),
      ],
    );
  }
}

class _UnlockedFeed extends ConsumerWidget {
  const _UnlockedFeed({
    required this.quest,
    required this.completions,
    required this.tab,
    required this.onTab,
  });

  final Quest quest;
  final List<QuestCompletion> completions;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameProvider.notifier);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      itemCount: completions.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SegmentedTabs(
              tabs: [context.l.tabFriends, context.l.tabFavorites],
              index: tab,
              onChanged: onTab,
            ),
          );
        }
        if (index == completions.length + 1) {
          // Le feed s'arrête : l'app renvoie vers l'action (§62).
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyState(
              emoji: '✨',
              title: context.l.upToDate,
              message: context.l.upToDateBody,
              actionLabel: context.l.findQuest,
              onAction: () => context.go('/home'),
            ),
          );
        }

        final completion = completions[index - 1];
        return QuestFeedCompletion(
          completion: completion,
          isMine: completion.author.id == ref.read(currentUserProvider)?.id,
          onReaction: (emoji) =>
              controller.toggleReaction(quest.id, completion.id, emoji),
          onComment: () => _openComments(context, ref, completion),
        );
      },
    );
  }

  void _openComments(BuildContext context, WidgetRef ref, QuestCompletion completion) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentsSheet(quest: quest, completion: completion),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.quest, required this.completion});

  final Quest quest;
  final QuestCompletion completion;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref
        .read(gameProvider.notifier)
        .addComment(widget.quest.id, widget.completion.id, text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final completion = ref
        .watch(gameProvider)
        .friendCompletions(widget.quest.id)
        .firstWhere((c) => c.id == widget.completion.id, orElse: () => widget.completion);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l.commentCount(completion.comments.length),
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                ),
                child: completion.comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text(context.l.firstToReact, style: AppTypography.body),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: completion.comments.length,
                        itemBuilder: (context, i) {
                          final comment = completion.comments[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserAvatar(
                                  seed: comment.author.id,
                                  name: comment.author.displayName,
                                  size: 30,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment.author.displayName,
                                            style: AppTypography.bodyStrong.copyWith(fontSize: 14),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            formatAgo(context.l, comment.ago),
                                            style: AppTypography.metadata,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(comment.text, style: AppTypography.body.copyWith(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTypography.bodyStrong,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.l.yourComment,
                        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surface1,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.chipR,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: AppRadius.chipR,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppRadius.chipR,
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GlassIconButton(icon: Icons.send_rounded, onPressed: _send),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
