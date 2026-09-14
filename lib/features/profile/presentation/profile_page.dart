import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user.dart' as models;
import '../../../shared/photos/avatar.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/loading_screen.dart';
import '../../../shared/widgets/misc.dart';
import '../../quests/domain/game_controller.dart';
import '../../../core/l10n/labels.dart';

/// Écran 16 — profil (§55, §193). Pas d'abonnés : ce qui compte, c'est ce qui
/// a été accompli.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingScreen();

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
            Row(
              children: [
                const Spacer(),
                GlassIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: UserAvatar(
                seed: user.id,
                name: user.displayName,
                size: 92,
                ring: true,
                ringWidth: 2.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(child: Text(user.displayName, style: AppTypography.screenTitle)),
            Center(
              child: Text('@${user.username}', style: AppTypography.metadata),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.chipR,
                  ),
                  child: Text(
                    context.l.level(user.level),
                    style: AppTypography.label.copyWith(fontSize: 11),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(user.title, style: AppTypography.bodyStrong),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            XPProgressBar(ratio: user.levelRatio),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                context.l.xpProgress(user.xp, user.xpForNextLevel),
                style: AppTypography.metadata,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: AppRadius.cardR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ProfileStat(
                    value: '${user.questsCompleted}',
                    label: context.l.statQuests,
                  ),
                  ProfileStat(value: '${user.streak}', label: context.l.statStreak),
                  ProfileStat(
                    value: '${user.badges.where((b) => b.unlocked).length}',
                    label: context.l.statBadges,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: context.l.categories),
            for (final progress in user.categories) CategoryProgressRow(progress: progress),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: context.l.badges),
            _Badges(badges: user.badges),
          ],
        ),
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.badges});

  final List<models.Badge> badges;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 0.95,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) {
        final badge = badges[i];
        return Opacity(
          opacity: badge.unlocked ? 1 : 0.35,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: AppRadius.cardR,
              border: Border.all(
                color: badge.unlocked ? AppColors.borderStrong : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  badge.title,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: AppTypography.metadata.copyWith(fontSize: 10.5),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
