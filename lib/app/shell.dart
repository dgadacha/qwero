import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/friends/presentation/create_sheet.dart';
import '../features/quests/domain/game_controller.dart';
import '../core/l10n/labels.dart';

/// Coque applicative : les quatre onglets et le bouton de création (§57, §102).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(gameProvider).pendingChallenges;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        index: navigationShell.currentIndex,
        friendsBadge: pending,
        onTap: (i) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        onCreate: () => showCreateSheet(context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.onCreate,
    this.friendsBadge = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;
  final int friendsBadge;

  static const _icons = [
    (icon: Icons.explore_outlined, active: Icons.explore_rounded),
    (icon: Icons.search_rounded, active: Icons.search_rounded),
    (icon: Icons.people_alt_outlined, active: Icons.people_alt_rounded),
    (icon: Icons.person_outline_rounded, active: Icons.person_rounded),
  ];

  List<String> _labels(L l) => [l.navQuests, l.navExplore, l.navFriends, l.navProfile];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom - 6 : AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _tab(context, 0),
            _tab(context, 1),
            SizedBox(
              width: 78,
              child: Center(child: _CreateButton(onTap: onCreate)),
            ),
            _tab(context, 2, badge: friendsBadge),
            _tab(context, 3),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, {int badge = 0}) {
    final item = _icons[i];
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? item.active : item.icon,
                  size: 23,
                  color: selected ? AppColors.primaryLight : AppColors.textTertiary,
                ),
                if (badge > 0)
                  Positioned(
                    right: -5,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.hard,
                        borderRadius: AppRadius.chipR,
                        border: Border.all(color: AppColors.surface1, width: 1.5),
                      ),
                      child: Text('$badge', style: AppTypography.label.copyWith(fontSize: 8.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _labels(context.l)[i],
              style: AppTypography.metadata.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primaryLight : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatefulWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: AppMotion.micro,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.primaryGlow(opacity: 0.5),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
