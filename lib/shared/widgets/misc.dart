import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../models/user.dart' as models;
import 'buttons.dart';
import '../../core/l10n/labels.dart';

/// État vide (§104) : un emoji, une phrase qui a du ton, une action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: actionLabel!, onPressed: onAction, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bloc de chargement (§105) : un shimmer plutôt qu'un spinner.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.small,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: const [AppColors.surface2, AppColors.surface3, AppColors.surface2],
            ),
          ),
        );
      },
    );
  }
}

/// Statistique du profil (§55).
class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.screenTitle.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.metadata, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Progression par catégorie (§56).
class CategoryProgressRow extends StatelessWidget {
  const CategoryProgressRow({super.key, required this.progress});

  final models.CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: AppRadius.smallR,
            ),
            alignment: Alignment.center,
            child: Text(progress.category.emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      progress.category.label(context.l),
                      style: AppTypography.bodyStrong.copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      context.l.level(progress.level),
                      style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        const ColoredBox(color: AppColors.surface3, child: SizedBox.expand()),
                        FractionallySizedBox(
                          widthFactor: progress.ratio,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                            child: SizedBox.expand(),
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
    );
  }
}

/// Carte d'intérêt de l'onboarding (§68).
class InterestCard extends StatelessWidget {
  const InterestCard({
    super.key,
    required this.category,
    required this.selected,
    this.onTap,
  });

  final QuestCategory category;
  final bool selected;
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
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surface1,
          borderRadius: AppRadius.cardR,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppShadows.glow(AppColors.primary, opacity: 0.25, blur: 18) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              category.label(context.l),
              style: AppTypography.metadata.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confettis de l'écran de réussite (§99).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.count = 32, this.play = true});

  final int count;
  final bool play;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _particles = List.generate(widget.count, (i) {
      return _Particle(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.25,
        speed: 0.55 + rnd.nextDouble() * 0.7,
        drift: (rnd.nextDouble() - 0.5) * 0.5,
        size: 5 + rnd.nextDouble() * 7,
        spin: (rnd.nextDouble() - 0.5) * 14,
        color: AppColors.confetti[i % AppColors.confetti.length],
        round: rnd.nextBool(),
      );
    });
    if (widget.play) _controller.forward();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double x;
  final double delay;
  final double speed;
  final double drift;
  final double size;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -0.1 + local * p.speed * 1.5;
      if (y > 1.1) continue;
      final x = p.x + math.sin(local * math.pi * 2 + p.x * 6) * p.drift * 0.3;
      final opacity = local > 0.75 ? (1 - (local - 0.75) / 0.25) : 1.0;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(local * p.spin);
      final paint = Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.38, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// En-tête de section (« QUÊTES DU JOUR », « Voir tout »).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                action!,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Onglets pleine largeur (Explorer, Amis, Feed).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.badges = const {},
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.chipR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.micro,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: i == index ? AppColors.primaryGradient : null,
                    borderRadius: AppRadius.chipR,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tabs[i],
                        style: AppTypography.metadata.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: i == index ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      if (badges[i] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: i == index ? Colors.white24 : AppColors.primary,
                            borderRadius: AppRadius.chipR,
                          ),
                          child: Text(
                            '${badges[i]}',
                            style: AppTypography.label.copyWith(fontSize: 9.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
