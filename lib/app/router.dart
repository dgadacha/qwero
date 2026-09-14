import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/dev/scene_gallery_page.dart';
import '../core/theme/app_theme.dart';
import '../features/camera/presentation/camera_page.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/feed/presentation/quest_feed_page.dart';
import '../features/friends/presentation/friends_page.dart';
import '../features/onboarding/presentation/add_friends_page.dart';
import '../features/onboarding/presentation/interests_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/settings_page.dart';
import '../features/quest_check/presentation/quest_check_page.dart';
import '../features/quest_check/presentation/quest_complete_page.dart';
import '../features/quests/presentation/home_page.dart';
import '../features/quests/presentation/quest_detail_page.dart';
import '../shared/models/quest.dart';
import 'shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: const String.fromEnvironment('START', defaultValue: '/splash'),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      // Réglage de la direction artistique, hors parcours utilisateur.
      GoRoute(path: '/scenes', builder: (_, _) => const SceneGalleryPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/interests', builder: (_, _) => const InterestsPage()),
      GoRoute(path: '/add-friends', builder: (_, _) => const AddFriendsPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/explore', builder: (_, _) => const ExplorePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/friends', builder: (_, _) => const FriendsPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfilePage())],
          ),
        ],
      ),
      GoRoute(
        path: '/quest',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuestDetailPage(quest: state.extra! as Quest),
      ),
      GoRoute(
        path: '/camera',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _fade(QuestCameraPage(quest: state.extra! as Quest)),
      ),
      GoRoute(
        path: '/check',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _fade(QuestCheckPage(args: state.extra! as QuestCheckArgs)),
      ),
      GoRoute(
        path: '/complete',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _fade(QuestCompletePage(args: state.extra! as QuestCompleteArgs)),
      ),
      GoRoute(
        path: '/feed',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuestFeedPage(quest: state.extra! as Quest),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
  );
});

/// Les moments de capture et de récompense s'enchaînent en fondu plutôt qu'en
/// glissement : l'utilisateur reste dans la même scène.
CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage(
  child: child,
  transitionDuration: AppMotion.screen,
  reverseTransitionDuration: AppMotion.screen,
  transitionsBuilder: (_, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
    child: child,
  ),
);
