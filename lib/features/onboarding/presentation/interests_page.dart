import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/misc.dart';
import '../../quests/domain/game_controller.dart';
import '../../../core/l10n/labels.dart';

/// Écran 03 (§68) : au moins trois catégories.
class InterestsPage extends ConsumerStatefulWidget {
  const InterestsPage({super.key});

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  static const _minimum = 3;
  static const _choices = [
    QuestCategory.adventure,
    QuestCategory.photography,
    QuestCategory.food,
    QuestCategory.sport,
    QuestCategory.music,
    QuestCategory.gaming,
    QuestCategory.nature,
    QuestCategory.creative,
    QuestCategory.social,
    QuestCategory.travel,
    QuestCategory.funny,
    QuestCategory.observation,
  ];

  final _selected = <QuestCategory>{};

  @override
  Widget build(BuildContext context) {
    final enough = _selected.length >= _minimum;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(context.l.interestsTitle, style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l.interestsSubtitle(_minimum), style: AppTypography.body),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: _choices.length,
                  itemBuilder: (context, i) {
                    final category = _choices[i];
                    return InterestCard(
                      category: category,
                      selected: _selected.contains(category),
                      onTap: () => setState(() {
                        if (!_selected.remove(category)) _selected.add(category);
                      }),
                    );
                  },
                ),
              ),
              AnimatedOpacity(
                opacity: enough ? 0 : 1,
                duration: AppMotion.micro,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    context.l.interestsRemaining(_minimum - _selected.length),
                    style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              PrimaryButton(
                label: context.l.next,
                onPressed: enough
                    ? () {
                        ref.read(gameProvider.notifier).completeOnboarding(_selected.toList());
                        context.go('/add-friends');
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
