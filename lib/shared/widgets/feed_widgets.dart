import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../models/completion.dart';
import '../models/user.dart';
import '../photos/avatar.dart';
import '../photos/scene_image.dart';
import '../../core/l10n/labels.dart';

/// Une participation dans le feed (§190).
class QuestFeedCompletion extends StatelessWidget {
  const QuestFeedCompletion({
    super.key,
    required this.completion,
    this.onReaction,
    this.onComment,
    this.isMine = false,
  });

  final QuestCompletion completion;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onComment;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(
              seed: completion.author.id,
              name: completion.author.displayName,
              size: 34,
              ring: isMine,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMine ? context.l.you : completion.author.displayName,
                      style: AppTypography.cardTitle.copyWith(fontSize: 14.5),
                    ),
                    if (completion.isFavorite) ...[
                      const SizedBox(width: 6),
                      const _FavoriteTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(formatAgo(context.l, completion.ago), style: AppTypography.metadata),
              ],
            ),
            const Spacer(),
            _MoreButton(onTap: onComment),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: SceneImage(completion.scene, borderRadius: AppRadius.cardR),
        ),
        if (completion.caption != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(completion.caption!, style: AppTypography.bodyStrong.copyWith(fontSize: 14.5)),
        ],
        const SizedBox(height: AppSpacing.sm),
        ReactionBar(
          reactions: completion.reactions,
          commentCount: completion.comments.length,
          onReaction: onReaction,
          onComment: onComment,
        ),
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FavoriteTag extends StatelessWidget {
  const _FavoriteTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.xp.withValues(alpha: 0.15),
        borderRadius: AppRadius.chipR,
        border: Border.all(color: AppColors.xp.withValues(alpha: 0.4)),
      ),
      child: Text(
        context.l.favorite,
        style: AppTypography.label.copyWith(color: AppColors.xp, fontSize: 9),
      ),
    );
  }
}

/// Barre de réactions (§25).
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.reactions,
    this.commentCount = 0,
    this.onReaction,
    this.onComment,
  });

  static const palette = ['🔥', '😂', '❤️', '🤯', '👏'];

  final List<Reaction> reactions;
  final int commentCount;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final reaction in reactions) ...[
          _ReactionPill(
            emoji: reaction.emoji,
            count: reaction.count,
            mine: reaction.mine,
            onTap: () => onReaction?.call(reaction.emoji),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        _AddReactionButton(
          onPick: (emoji) => onReaction?.call(emoji),
          taken: reactions.map((r) => r.emoji).toSet(),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onComment,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(Icons.mode_comment_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 5),
              Text('$commentCount', style: AppTypography.metadata),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.mine,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: AppMotion.micro,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface2,
          borderRadius: AppRadius.chipR,
          border: Border.all(color: mine ? AppColors.borderPrimary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppTypography.metadata.copyWith(
                color: mine ? AppColors.primaryLight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({required this.onPick, required this.taken});

  final void Function(String emoji) onPick;
  final Set<String> taken;

  @override
  Widget build(BuildContext context) {
    final available = ReactionBar.palette.where((e) => !taken.contains(e)).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      color: AppColors.surface3,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonR),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (emoji) {
        HapticFeedback.lightImpact();
        onPick(emoji);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          height: 44,
          child: Row(
            children: [
              for (final emoji in available)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    onPick(emoji);
                  },
                  borderRadius: AppRadius.chipR,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: AppRadius.chipR,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.add_reaction_outlined, size: 15, color: AppColors.textTertiary),
      ),
    );
  }
}

/// Ligne « ami a participé » du reveal social (§132).
class FriendProgressRow extends StatelessWidget {
  const FriendProgressRow({super.key, required this.friend, required this.done});

  final Friend friend;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          UserAvatar(seed: friend.id, name: friend.displayName, size: 30),
          const SizedBox(width: AppSpacing.sm),
          Text(friend.displayName, style: AppTypography.bodyStrong.copyWith(fontSize: 14.5)),
          const Spacer(),
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: done ? AppColors.success : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

