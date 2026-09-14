import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/backend/backend_mode.dart';
import '../core/dev/scene_gallery_page.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/auth/presentation/create_profile_page.dart';
import '../features/auth/presentation/sign_in_page.dart';
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

/// Écrans accessibles sans être connecté.
const _publicRoutes = {'/splash', '/onboarding', '/interests', '/signin', '/scenes'};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: const String.fromEnvironment('START', defaultValue: '/splash'),
    // Le routeur se réévalue à chaque changement d'authentification.
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final status = ref.read(authStatusProvider);
      final location = state.matchedLocation;

      // Une fois le pseudo choisi, le parcours reprend à l'ajout d'amis, pas
      // au tableau des quêtes : c'est l'ordre de l'onboarding (§65).
      if (location == '/profile-setup' && status == AuthStatus.ready) {
        return '/add-friends';
      }
      if (location == '/signin') {
        return switch (status) {
          AuthStatus.needsProfile => '/profile-setup',
          AuthStatus.ready => '/home',
          _ => null,
        };
      }

      // Sans backend, la session ne gouverne rien d'autre : le prototype reste
      // traversable de bout en bout sans se connecter.
      if (!Backend.isFirebase) return null;

      // Premier chargement : on laisse le splash tenir l'écran.
      if (status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.signedOut) {
        return _publicRoutes.contains(location) ? null : '/signin';
      }

      // Connecté sans profil : le pseudo manque, rien d'autre n'a de sens.
      if (status == AuthStatus.needsProfile) {
        return location == '/profile-setup' ? null : '/profile-setup';
      }

      if (location == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      // Réglage de la direction artistique, hors parcours utilisateur.
      GoRoute(path: '/scenes', builder: (_, _) => const SceneGalleryPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: '/signin',
        builder: (_, state) =>
            SignInPage(startOnRegister: state.uri.queryParameters['mode'] == 'register'),
      ),
      GoRoute(path: '/profile-setup', builder: (_, _) => const CreateProfilePage()),
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

/// Relaie les changements d'authentification au routeur.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    _subscription = ref.listen(
      authStatusProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
    ref.onDispose(() => _subscription.close());
  }

  late final ProviderSubscription<AuthStatus> _subscription;
}

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
