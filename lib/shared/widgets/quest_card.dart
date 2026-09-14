import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../models/quest.dart';
import '../photos/scene_image.dart';
import 'badges.dart';
import '../../core/l10n/labels.dart';

/// Carte de quête du tableau (§28, §184, §185).
///
/// L'image occupe le tiers droit de la carte, jamais la totalité : la carte
/// reste sombre et le titre garde son contraste.
class QuestCard extends StatefulWidget {
  const QuestCard({
    super.key,
    required this.quest,
    this.completed = false,
    this.onTap,
  });

  final Quest quest;
  final bool completed;
  final VoidCallback? onTap;

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final color = quest.difficulty.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: AppMotion.micro,
        curve: AppMotion.standard,
        child: Container(
          height: 142,
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardR,
            border: Border.all(
              color: widget.completed
                  ? AppColors.success.withValues(alpha: 0.35)
                  : color.withValues(alpha: 0.22),
            ),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardR,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond : dégradé sombre teinté par la difficulté (§185).
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color.lerp(AppColors.surface1, color, 0.1)!,
                        AppColors.surface1,
                      ],
                    ),
                  ),
                ),
                // Visuel à droite, fondu vers la gauche.
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 150,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.white, Colors.white],
                      stops: [0.0, 0.45, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: SceneImage(quest.scene),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          QuestDifficultyBadge(quest.difficulty),
                          const Spacer(),
                          XPBadge(quest.xpReward),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 190,
                        child: Text(
                          quest.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.questTitle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (widget.completed) ...[
                            const Icon(Icons.check_circle_rounded,
                                size: 15, color: AppColors.success),
                            const SizedBox(width: 5),
                            Text(
                              context.l.questDone,
                              style: AppTypography.metadata
                                  .copyWith(color: AppColors.success),
                            ),
                          ] else ...[
                            Text(
                              context.l.minutes(quest.estimatedMinutes),
                              style: AppTypography.metadata,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Text('·', style: AppTypography.metadata),
                            const SizedBox(width: AppSpacing.xs),
                            Text(quest.category.label(context.l), style: AppTypography.metadata),
                          ],
                          const Spacer(),
                          _Arrow(color: widget.completed ? AppColors.success : color),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: color),
    );
  }
}

/// Grande carte immersive : World Quest de l'écran Explorer (§191).
class WorldQuestCard extends StatelessWidget {
  const WorldQuestCard({super.key, required this.quest, this.onTap, this.completed = false});

  final Quest quest;
  final VoidCallback? onTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        height: 232,
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardR,
          border: Border.all(color: AppColors.world.withValues(alpha: 0.3)),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardR,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SceneImage(quest.scene, scrim: true),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.world.withValues(alpha: 0.2),
                            borderRadius: AppRadius.chipR,
                            border: Border.all(color: AppColors.world.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌎', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                context.l.worldQuest,
                                style: AppTypography.label.copyWith(color: AppColors.world),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (quest.worldNumber != null)
                          Text(
                            quest.worldNumber!,
                            style: AppTypography.label.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      quest.title.toUpperCase(),
                      style: AppTypography.hero.copyWith(fontSize: 27, height: 1.05),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          context.l.participations(_formatCount(quest.participantCount)),
                          style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        XPBadge(quest.xpReward),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadius.buttonR,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              completed ? Icons.public_rounded : Icons.play_arrow_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              completed ? context.l.seeParticipations : context.l.startQuest,
                              style: const TextStyle(
                                fontFamily: AppTypography.family,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCount(int value) {
  if (value < 1000) return '$value';
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

/// Petite carte de quête utilisée dans les grilles (tendances, communauté).
class QuestTile extends StatelessWidget {
  const QuestTile({super.key, required this.quest, this.onTap});

  final Quest quest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardR,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardR,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SceneImage(quest.scene, scrim: true),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      quest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(fontSize: 13.5, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            size: 12, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          _compact(quest.participantCount),
                          style: AppTypography.metadata.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}
