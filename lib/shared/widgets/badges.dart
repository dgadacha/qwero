import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../../core/l10n/labels.dart';

/// Pastille de difficulté (§28).
class QuestDifficultyBadge extends StatelessWidget {
  const QuestDifficultyBadge(this.difficulty, {super.key, this.compact = false});

  final QuestDifficulty difficulty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = difficulty.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.chipR,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(color, opacity: 0.6, blur: 8),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            difficulty.label(context.l),
            style: AppTypography.label.copyWith(
              color: color,
              fontSize: compact ? 9.5 : 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Récompense en XP (§28).
class XPBadge extends StatelessWidget {
  const XPBadge(this.xp, {super.key, this.compact = false, this.color});

  final int xp;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.xp;
    return Text(
      '+$xp XP',
      style: TextStyle(
        fontFamily: AppTypography.family,
        fontSize: compact ? 11.5 : 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: tint,
      ),
    );
  }
}

/// Compteur de streak (§53).
class StreakBadge extends StatelessWidget {
  const StreakBadge(this.days, {super.key, this.large = false});

  final int days;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🔥', style: TextStyle(fontSize: large ? 18 : 14)),
        const SizedBox(width: 6),
        Text(
          context.l.streakDays(days),
          style: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: large ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: AppColors.streak,
          ),
        ),
      ],
    );
  }
}

/// Critère affiché avant participation (§30).
class QuestRequirementChip extends StatelessWidget {
  const QuestRequirementChip({super.key, required this.emoji, required this.label, this.done});

  final String emoji;
  final String label;
  final bool? done;

  @override
  Widget build(BuildContext context) {
    final ok = done == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? AppColors.success.withValues(alpha: 0.12) : AppColors.surface2,
        borderRadius: AppRadius.chipR,
        border: Border.all(color: ok ? AppColors.success.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.metadata.copyWith(
              color: ok ? AppColors.success : AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression d'XP (§27).
class XPProgressBar extends StatelessWidget {
  const XPProgressBar({
    super.key,
    required this.ratio,
    this.height = 8,
    this.showPercent = false,
  });

  final double ratio;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  const ColoredBox(color: AppColors.surface3, child: SizedBox.expand()),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.5, blur: 10),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showPercent) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(ratio * 100).round()}%',
            style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
