import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../quests/domain/game_controller.dart';
import '../domain/quest_check_service.dart';
import 'quest_complete_page.dart';
import '../../../core/l10n/labels.dart';

class QuestCheckArgs {
  const QuestCheckArgs({required this.quest, required this.scene});

  final Quest quest;
  final Scene scene;
}

/// Écran 09 — analyse de la preuve (§37, §188).
///
/// Les contrôles tombent un par un : l'utilisateur voit ce qui est vérifié
/// plutôt qu'un sablier.
class QuestCheckPage extends ConsumerStatefulWidget {
  const QuestCheckPage({super.key, required this.args});

  final QuestCheckArgs args;

  @override
  ConsumerState<QuestCheckPage> createState() => _QuestCheckPageState();
}

class _QuestCheckPageState extends ConsumerState<QuestCheckPage> {
  late final QuestCheckResult _result = QuestCheckService.analyse(
    quest: widget.args.quest,
    scene: widget.args.scene,
  );

  int _revealed = 0;
  Timer? _timer;
  bool _retried = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 620), (timer) {
      if (_revealed >= _result.checks.length) {
        timer.cancel();
        _finish();
        return;
      }
      setState(() => _revealed += 1);
      final check = _result.checks[_revealed - 1];
      if (check.passed) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_result.verdict == QuestCheckVerdict.pass) {
      Future.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        ref.read(gameProvider.notifier).completeQuest(
              quest: widget.args.quest,
              scene: widget.args.scene,
              result: _result,
            );
        context.pushReplacement(
          '/complete',
          extra: QuestCompleteArgs(
            quest: widget.args.quest,
            scene: widget.args.scene,
            result: _result,
          ),
        );
      });
    } else {
      setState(() {});
    }
  }

  bool get _done => _revealed >= _result.checks.length;
  bool get _failed => _done && _result.verdict != QuestCheckVerdict.pass;

  @override
  Widget build(BuildContext context) {
    final progress = _result.checks.isEmpty ? 1.0 : _revealed / _result.checks.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SceneImage(widget.args.scene),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x59080C14), Color(0x8C080C14), Color(0xF2080C14)],
                stops: [0.0, 0.5, 0.86],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                  child: _failed ? _FailCard(result: _result, onRetry: _retry, onContest: _contest, retried: _retried) : _AnalysisCard(
                    result: _result,
                    revealed: _revealed,
                    progress: progress,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _retry() => context.pushReplacement('/camera', extra: widget.args.quest);

  /// Contestation (§40) : une seule demande par participation.
  void _contest() {
    setState(() => _retried = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.contestToast)),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.result,
    required this.revealed,
    required this.progress,
  });

  final QuestCheckResult result;
  final int revealed;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface1.withValues(alpha: 0.92),
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 17)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l.analysing,
                style: AppTypography.label.copyWith(letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < result.checks.length; i++)
            _CheckRow(check: result.checks[i], revealed: i < revealed),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppMotion.screen,
            builder: (context, value, _) => Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          const ColoredBox(color: AppColors.surface3, child: SizedBox.expand()),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(value * 100).round()}%',
                  style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de vérification, qui apparaît en fondu + léger glissement (§97).
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check, required this.revealed});

  final QuestCheckItem check;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: revealed ? 1 : 0.28,
      duration: AppMotion.microSlow,
      child: AnimatedSlide(
        offset: revealed ? Offset.zero : const Offset(0, 0.25),
        duration: AppMotion.microSlow,
        curve: AppMotion.standard,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: revealed
                    ? Icon(
                        check.passed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: check.passed ? AppColors.success : AppColors.hard,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  checkLabel(context.l, check.id, check.label),
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: 14.5,
                    color: revealed && !check.passed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Échec : on ne dit jamais « FAIL » (§39).
class _FailCard extends StatelessWidget {
  const _FailCard({
    required this.result,
    required this.onRetry,
    required this.onContest,
    required this.retried,
  });

  final QuestCheckResult result;
  final VoidCallback onRetry;
  final VoidCallback onContest;
  final bool retried;

  @override
  Widget build(BuildContext context) {
    final missing = result.checks.where((c) => !c.passed).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface1.withValues(alpha: 0.95),
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤔', style: TextStyle(fontSize: 30)),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l.notSure, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            missing.isEmpty
                ? context.l.reasonUncertain
                : context.l.missingCriteria(
                    missing
                        .map((c) => checkLabel(context.l, c.id, c.label).toLowerCase())
                        .join(', '),
                  ),
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: context.l.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: retried ? context.l.contestSent : context.l.contest,
            onPressed: retried ? null : onContest,
          ),
        ],
      ),
    );
  }
}
