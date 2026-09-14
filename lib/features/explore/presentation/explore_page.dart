import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/widgets/misc.dart';
import '../../../shared/widgets/quest_card.dart';
import '../../quests/data/mock_data.dart';
import '../../quests/domain/game_controller.dart';
import '../../quests/domain/game_state.dart';
import '../../../core/l10n/labels.dart';

/// Écran 12 — Explorer (§59, §191).
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.sm,
            AppSpacing.screenH,
            110,
          ),
          children: [
            Text(context.l.exploreTitle, style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.md),
            SegmentedTabs(
              tabs: [context.l.tabWorld, context.l.tabTrending, context.l.tabCommunity],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.md),
            switch (_tab) {
              0 => _WorldTab(game: game),
              1 => _GridTab(quests: MockData.trending, title: context.l.mostDoneToday),
              _ => _GridTab(quests: MockData.community, title: context.l.communityMade),
            },
          ],
        ),
      ),
    );
  }
}

class _WorldTab extends StatelessWidget {
  const _WorldTab({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final world = game.todaySet?.world;
    if (world == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Skeleton(height: 232, radius: AppRadius.card),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorldQuestCard(
          quest: world,
          completed: game.isCompleted(world.id),
          onTap: () => game.isCompleted(world.id)
              ? context.push('/feed', extra: world)
              : context.push('/quest', extra: world),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: context.l.trendingQuests),
        _QuestGrid(quests: MockData.trending.take(4).toList()),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: context.l.aroundTheWorld),
        _WorldStats(count: world.participantCount),
      ],
    );
  }
}

class _GridTab extends StatelessWidget {
  const _GridTab({required this.quests, required this.title});

  final List<Quest> quests;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        _QuestGrid(quests: quests),
      ],
    );
  }
}

class _QuestGrid extends StatelessWidget {
  const _QuestGrid({required this.quests});

  final List<Quest> quests;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.92,
      ),
      itemCount: quests.length,
      itemBuilder: (context, i) => QuestTile(
        quest: quests[i],
        onTap: () => context.push('/quest', extra: quests[i]),
      ),
    );
  }
}

/// Agrégats seulement : jamais de position précise (§166, §167).
class _WorldStats extends StatelessWidget {
  const _WorldStats({required this.count});

  final int count;

  static const _regions = [
    ('🇫🇷 France', 0.82),
    ('🇯🇵 Japon', 0.64),
    ('🇺🇸 États-Unis', 0.58),
    ('🇧🇷 Brésil', 0.41),
    ('🇳🇨 Nouvelle-Calédonie', 0.22),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.cardR,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: AppTypography.hero.copyWith(fontSize: 27)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.l.participationsWord,
                  style: AppTypography.body.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, ratio) in _regions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      label,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: Stack(
                          children: [
                            const ColoredBox(color: AppColors.surface3, child: SizedBox.expand()),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: const ColoredBox(
                                color: AppColors.world,
                                child: SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
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
