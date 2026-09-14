import 'dart:async';

import 'auth_repository.dart';

/// Authentification simulée.
///
/// Aucune vérification : le prototype doit rester traversable sans backend.
/// Les règles de forme (adresse plausible, mot de passe non vide) sont
/// conservées pour que l'écran se comporte comme en production.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthState>.broadcast();
  AuthState _state = const AuthState(status: AuthStatus.signedOut);

  @override
  Stream<AuthState> watch() async* {
    yield _state;
    yield* _controller.stream;
  }

  void _emit(AuthState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!email.contains('@') || password.isEmpty) {
      throw const AuthException('Adresse e-mail ou mot de passe incorrect.');
    }
    _emit(AuthState(status: AuthStatus.ready, userId: 'u_me', email: email));
  }

  @override
  Future<void> register({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!email.contains('@')) {
      throw const AuthException("Cette adresse e-mail n'est pas valide.");
    }
    if (password.length < 6) {
      throw const AuthException('Choisis un mot de passe un peu plus solide.');
    }
    _emit(AuthState(status: AuthStatus.needsProfile, userId: 'u_me', email: email));
  }

  @override
  Future<void> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _emit(const AuthState(status: AuthStatus.needsProfile, userId: 'u_me'));
  }

  @override
  Future<void> createProfile({
    required String username,
    required String displayName,
    required String timezone,
    required String locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (username == 'dylan') {
      // Un pseudo déjà pris, pour que l'écran montre ce cas au moins une fois.
      throw const AuthException('Ce pseudo est déjà pris.');
    }
    _emit(AuthState(status: AuthStatus.ready, userId: 'u_me', email: _state.email));
  }

  @override
  Future<void> signOut() async =>
      _emit(const AuthState(status: AuthStatus.signedOut));
}
