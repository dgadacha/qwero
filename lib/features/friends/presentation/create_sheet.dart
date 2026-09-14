import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/widgets/buttons.dart';
import '../../quests/domain/game_controller.dart';
import '../../../core/l10n/labels.dart';

/// Feuille du bouton central (§103, §198). Aucune option coop au MVP.
Future<void> showCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l.whatDoYouWant, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _Option(
              emoji: '⚔️',
              title: context.l.sendChallenge,
              subtitle: context.l.challengeAFriend,
              onTap: () {
                Navigator.pop(context);
                showChallengeComposer(context);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _Option(
              emoji: '✨',
              title: context.l.createQuest,
              subtitle: context.l.createQuestBody,
              onTap: () {
                Navigator.pop(context);
                showChallengeComposer(context, community: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: AppRadius.cardR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.metadata),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Composition d'un challenge (§43, §44).
Future<void> showChallengeComposer(BuildContext context, {bool community = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ChallengeComposer(community: community),
  );
}

class _ChallengeComposer extends ConsumerStatefulWidget {
  const _ChallengeComposer({required this.community});

  final bool community;

  @override
  ConsumerState<_ChallengeComposer> createState() => _ChallengeComposerState();
}

class _ChallengeComposerState extends ConsumerState<_ChallengeComposer> {
  final _controller = TextEditingController();
  Friend? _target;
  bool _parsing = false;

  /// Ce que l'analyse de la consigne produira côté Claude (§44) : ici, une
  /// approximation locale à partir de mots-clés, pour montrer l'intention.
  List<QuestRequirement> get _requirements {
    final text = _controller.text.toLowerCase();
    return [
      const QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
      if (text.contains('dehors') || text.contains('extérieur') || text.contains('rue'))
        const QuestRequirement(id: 'outdoor', label: 'Extérieur', emoji: '🌳'),
      if (text.contains('voiture')) const QuestRequirement(id: 'car', label: 'Une voiture', emoji: '🚗'),
      if (text.contains('rouge')) const QuestRequirement(id: 'color_red', label: 'Rouge', emoji: '🔴'),
      if (text.contains('jaune'))
        const QuestRequirement(id: 'color_yellow', label: 'Jaune', emoji: '🟡'),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final l = context.l;
    setState(() => _parsing = true);
    // Le temps que mettrait l'aller-retour d'analyse et de modération.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final target = _target;
    if (target != null) {
      ref.read(gameProvider.notifier).sendChallenge(
            to: target,
            quest: Quest(
              id: 'q_user_${DateTime.now().microsecondsSinceEpoch}',
              title: text,
              description: 'Challenge lancé par toi.',
              category: QuestCategory.funny,
              difficulty: QuestDifficulty.medium,
              xpReward: 150,
              estimatedMinutes: 20,
              scene: Scene.nightCity,
              requirements: _requirements,
            ),
          );
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.community
              ? l.questSentToModeration
              : l.challengeSentTo(target?.displayName ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(gameProvider).friends;
    final ready = _controller.text.trim().isNotEmpty && (widget.community || _target != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            0,
            AppSpacing.screenH,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.community ? context.l.createQuest : context.l.sendChallenge,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l.composerSubtitle,
                style: AppTypography.body.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                maxLength: 90,
                style: AppTypography.bodyStrong,
                decoration: InputDecoration(
                  hintText: context.l.composerHint,
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface1,
                  counterStyle: AppTypography.metadata,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              if (_controller.text.trim().isNotEmpty) ...[
                Text(
                  context.l.detectedCriteria,
                  style: AppTypography.label.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final requirement in _requirements)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: AppRadius.chipR,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${requirement.emoji} '
                          '${requirementLabel(context.l, requirement.id, requirement.label)}',
                          style: AppTypography.metadata,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (!widget.community) ...[
                Text(
                  context.l.sendTo,
                  style: AppTypography.label.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 78,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    itemBuilder: (context, i) {
                      final friend = friends[i];
                      final selected = _target?.id == friend.id;
                      return GestureDetector(
                        onTap: () => setState(() => _target = friend),
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Column(
                            children: [
                              UserAvatar(
                                seed: friend.id,
                                name: friend.displayName,
                                size: 46,
                                ring: selected,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                friend.displayName,
                                style: AppTypography.metadata.copyWith(
                                  color: selected
                                      ? AppColors.primaryLight
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              PrimaryButton(
                label: widget.community ? context.l.proposeQuest : context.l.sendChallengeCta,
                loading: _parsing,
                onPressed: ready ? _send : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
