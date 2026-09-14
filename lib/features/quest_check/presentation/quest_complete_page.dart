import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/misc.dart';
import '../../quests/domain/game_controller.dart';
import '../../../core/l10n/labels.dart';

class QuestCompleteArgs {
  const QuestCompleteArgs({
    required this.quest,
    required this.scene,
    required this.completion,
  });

  final Quest quest;
  final Scene scene;
  final QuestCompletion completion;
}

/// Écran 10 — réussite (§38, §189).
///
/// Séquence du §197 : orbe, coche, titre, XP, confettis, photo, déverrouillage.
class QuestCompletePage extends ConsumerStatefulWidget {
  const QuestCompletePage({super.key, required this.args});

  final QuestCompleteArgs args;

  @override
  ConsumerState<QuestCompletePage> createState() => _QuestCompletePageState();
}

class _QuestCompletePageState extends ConsumerState<QuestCompletePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  // Les bornes correspondent au découpage du §197, ramené sur 1600 ms.
  late final _orb = _interval(0.09, 0.34);
  late final _check = _interval(0.22, 0.44);
  late final _title = _interval(0.34, 0.56);
  late final _xp = _interval(0.5, 0.72);
  late final _photo = _interval(0.72, 0.95);

  bool _confetti = false;

  CurvedAnimation _interval(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addListener(_haptics);
  }

  void _haptics() {
    final t = _controller.value;
    if (!_confetti && t >= 0.62) {
      setState(() => _confetti = true);
      HapticFeedback.heavyImpact();
    }
  }

  /// La séquence reste sautable (§98).
  void _skip() {
    if (_controller.isAnimating) {
      _controller.forward(from: 1);
      setState(() => _confetti = true);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_haptics)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.args.quest;
    final user = ref.watch(currentUserProvider);
    final passed = widget.args.completion.checks.where((c) => c.passed).toList();

    return Scaffold(
      body: GestureDetector(
        onTap: _skip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond : la scène capturée, très assombrie.
            Opacity(opacity: 0.35, child: SceneImage(widget.args.scene)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [Color(0xCC101722), Color(0xF7080C14)],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    FadeTransition(
                      opacity: _orb,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.4, end: 1.0).animate(
                          CurvedAnimation(parent: _orb, curve: Curves.easeOutBack),
                        ),
                        child: _SuccessOrb(check: _check),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeTransition(
                      opacity: _title,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_title),
                        child: Text(
                          context.l.questComplete,
                          style: AppTypography.hero,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FadeTransition(
                      opacity: _xp,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(
                          CurvedAnimation(parent: _xp, curve: Curves.easeOutBack),
                        ),
                        child: Text(
                          context.l.xpGained(widget.args.completion.xpAwarded),
                          style: AppTypography.hero.copyWith(
                            fontSize: 38,
                            color: AppColors.xp,
                            shadows: [
                              BoxShadow(
                                color: AppColors.xp.withValues(alpha: 0.45),
                                blurRadius: 26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeTransition(
                      opacity: _photo,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(_photo),
                        child: Column(
                          children: [
                            Container(
                              height: 190,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.cardR,
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                                boxShadow: AppShadows.glow(
                                  AppColors.success,
                                  opacity: 0.2,
                                  blur: 30,
                                ),
                              ),
                              child: SceneImage(
                                widget.args.scene,
                                borderRadius: AppRadius.cardR,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final check in passed.take(3))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_rounded,
                                            size: 16, color: AppColors.success),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          checkLabel(context.l, check.id, check.label),
                                          style: AppTypography.bodyStrong.copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.surface1,
                                borderRadius: AppRadius.buttonR,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  StreakBadge(user?.streak ?? 0, large: true),
                                  const Spacer(),
                                  Text(
                                    context.l.level(user?.level ?? 1),
                                    style: AppTypography.bodyStrong.copyWith(
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_open_rounded,
                                    size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 6),
                                Text(
                                  context.l.friendResultsUnlocked,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              label: context.l.seeParticipations,
                              icon: Icons.visibility_rounded,
                              onPressed: () {
                                context.pushReplacement('/feed', extra: quest);
                              },
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SecondaryButton(
                              label: context.l.backHome,
                              onPressed: () => context.go('/home'),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_confetti) const ConfettiOverlay(),
          ],
        ),
      ),
    );
  }
}

/// Orbe de réussite : halo vert, coche qui se trace (§98).
class _SuccessOrb extends StatelessWidget {
  const _SuccessOrb({required this.check});

  final Animation<double> check;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.35),
            AppColors.success.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2),
        boxShadow: AppShadows.glow(AppColors.success, opacity: 0.45, blur: 42),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: check,
          builder: (context, _) => CustomPaint(
            size: const Size(46, 46),
            painter: _CheckPainter(check.value),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final start = Offset(size.width * 0.18, size.height * 0.52);
    final elbow = Offset(size.width * 0.42, size.height * 0.74);
    final end = Offset(size.width * 0.84, size.height * 0.27);

    final path = Path()..moveTo(start.dx, start.dy);
    if (progress <= 0.45) {
      final t = progress / 0.45;
      path.lineTo(start.dx + (elbow.dx - start.dx) * t, start.dy + (elbow.dy - start.dy) * t);
    } else {
      final t = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
      path
        ..lineTo(elbow.dx, elbow.dy)
        ..lineTo(elbow.dx + (end.dx - elbow.dx) * t, elbow.dy + (end.dy - elbow.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
