import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../quests/domain/game_controller.dart';
import 'quest_complete_page.dart';

class QuestCheckArgs {
  const QuestCheckArgs({
    required this.quest,
    required this.scene,
    required this.imageBytes,
    required this.capturedAt,
  });

  final Quest quest;
  final Scene scene;
  final Uint8List imageBytes;
  final DateTime capturedAt;
}

/// Écran 09 — analyse de la preuve (§37, §188).
///
/// Le verdict vient du serveur (§8). L'écran envoie la preuve, puis suit la
/// participation jusqu'à ce qu'elle soit tranchée. Les contrôles apparaissent
/// un par un : l'utilisateur voit ce qui est vérifié, plutôt qu'un sablier.
class QuestCheckPage extends ConsumerStatefulWidget {
  const QuestCheckPage({super.key, required this.args});

  final QuestCheckArgs args;

  @override
  ConsumerState<QuestCheckPage> createState() => _QuestCheckPageState();
}

class _QuestCheckPageState extends ConsumerState<QuestCheckPage> {
  StreamSubscription<QuestCompletion>? _subscription;
  Timer? _reveal;

  QuestCompletion? _completion;
  String? _error;

  /// Contrôles déjà dévoilés. Tant que le serveur n'a pas répondu, ce sont les
  /// critères attendus de la quête qui défilent.
  int _revealed = 0;
  bool _contested = false;

  List<QuestCheckItem> get _checks {
    final completion = _completion;
    if (completion != null && completion.checks.isNotEmpty) return completion.checks;
    return [
      for (final requirement in widget.args.quest.requirements)
        QuestCheckItem(id: requirement.id, label: requirement.label, passed: true),
    ];
  }

  bool get _settled =>
      _completion != null && _completion!.status != CompletionStatus.analyzing;

  bool get _failed =>
      _settled && _completion!.status != CompletionStatus.validated;

  @override
  void initState() {
    super.initState();
    _submit();
    // Le rythme d'apparition est indépendant de la latence serveur : une
    // réponse instantanée ne doit pas escamoter l'animation, une réponse lente
    // ne doit pas figer l'écran.
    _reveal = Timer.periodic(const Duration(milliseconds: 620), (timer) {
      if (_revealed >= _checks.length) {
        if (_settled) {
          timer.cancel();
          _finish();
        }
        return;
      }
      setState(() => _revealed += 1);
      final check = _checks[_revealed - 1];
      if (check.passed) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _submit() async {
    final completionId = await ref.read(gameProvider.notifier).submitProof(
          quest: widget.args.quest,
          imageBytes: widget.args.imageBytes,
          capturedAt: widget.args.capturedAt,
        );

    if (!mounted) return;
    if (completionId == null) {
      setState(() => _error = ref.read(gameProvider).error);
      return;
    }

    _subscription = ref
        .read(gameProvider.notifier)
        .watchCompletion(completionId)
        .listen(
          (completion) => setState(() => _completion = completion),
          onError: (Object error) => setState(() => _error = error.toString()),
        );
  }

  @override
  void dispose() {
    _reveal?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _finish() {
    final completion = _completion;
    if (completion == null) return;
    if (completion.status != CompletionStatus.validated) {
      setState(() {});
      return;
    }

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      context.pushReplacement(
        '/complete',
        extra: QuestCompleteArgs(
          quest: widget.args.quest,
          scene: widget.args.scene,
          completion: completion,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final checks = _checks;
    final progress = checks.isEmpty ? 1.0 : _revealed / checks.length;

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
                  child: _error != null
                      ? _ErrorCard(message: _error!, onRetry: _retry)
                      : _failed
                          ? _FailCard(
                              completion: _completion!,
                              onRetry: _retry,
                              onContest: _contest,
                              contested: _contested,
                            )
                          : _AnalysisCard(
                              checks: checks,
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
  Future<void> _contest() async {
    final completion = _completion;
    if (completion == null) return;

    setState(() => _contested = true);
    await ref.read(gameProvider.notifier).contest(completion.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.contestToast)),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.checks,
    required this.revealed,
    required this.progress,
  });

  final List<QuestCheckItem> checks;
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
          for (var i = 0; i < checks.length; i++)
            _CheckRow(check: checks[i], revealed: i < revealed),
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
                        check.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
    required this.completion,
    required this.onRetry,
    required this.onContest,
    required this.contested,
  });

  final QuestCompletion completion;
  final VoidCallback onRetry;
  final VoidCallback onContest;
  final bool contested;

  @override
  Widget build(BuildContext context) {
    final missing = completion.checks.where((c) => !c.passed).toList();

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
            label: contested ? context.l.contestSent : context.l.contest,
            onPressed: contested ? null : onContest,
          ),
        ],
      ),
    );
  }
}

/// Envoi impossible : la quête n'est pas perdue, seulement l'envoi (§106).
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface1.withValues(alpha: 0.95),
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📡', style: TextStyle(fontSize: 30)),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: context.l.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
