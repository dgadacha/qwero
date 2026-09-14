import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_mode.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../data/mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return Backend.isFirebase ? FirebaseAuthRepository() : MockAuthRepository();
});

/// État d'authentification observé par le routeur.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).watch();
});

/// Vue synchrone, pratique pour la redirection : l'état inconnu du premier
/// chargement ne doit pas envoyer le joueur sur l'écran de connexion.
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (state) => state.status,
        orElse: () => AuthStatus.unknown,
      );
});
