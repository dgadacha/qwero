import 'package:flutter_test/flutter_test.dart';
import 'package:qwero/features/auth/data/auth_repository.dart';
import 'package:qwero/features/auth/data/mock_auth_repository.dart';

/// Comportement attendu de l'écran de compte, indépendamment du backend.
///
/// L'implémentation Firebase applique les mêmes règles ; ce qui compte ici,
/// c'est l'enchaînement des états que le routeur observe.
void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  test('on démarre déconnecté', () async {
    final state = await auth.watch().first;
    expect(state.status, AuthStatus.signedOut);
  });

  test("créer un compte mène à l'étape du pseudo", () async {
    await auth.register(email: 'dylan@example.com', password: 'motdepasse');

    final state = await auth.watch().first;
    expect(state.status, AuthStatus.needsProfile);
    expect(state.userId, isNotNull);
  });

  test('un pseudo enregistré rend le compte complet', () async {
    await auth.register(email: 'dylan@example.com', password: 'motdepasse');
    await auth.createProfile(
      username: 'dylan_nc',
      displayName: 'Dylan',
      timezone: 'Pacific/Noumea',
      locale: 'fr',
    );

    final state = await auth.watch().first;
    expect(state.status, AuthStatus.ready);
  });

  test('un pseudo déjà pris est refusé', () async {
    await auth.register(email: 'dylan@example.com', password: 'motdepasse');

    expect(
      () => auth.createProfile(
        username: 'dylan',
        displayName: 'Dylan',
        timezone: 'Pacific/Noumea',
        locale: 'fr',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('une adresse invalide est refusée', () async {
    expect(
      () => auth.register(email: 'pas-une-adresse', password: 'motdepasse'),
      throwsA(isA<AuthException>()),
    );
  });

  test('un mot de passe trop court est refusé', () async {
    expect(
      () => auth.register(email: 'dylan@example.com', password: '123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('essayer sans compte mène aussi au choix du pseudo', () async {
    await auth.signInAnonymously();

    final state = await auth.watch().first;
    expect(state.status, AuthStatus.needsProfile);
  });

  test('la déconnexion ramène à l\'état déconnecté', () async {
    await auth.signIn(email: 'dylan@example.com', password: 'motdepasse');
    expect((await auth.watch().first).status, AuthStatus.ready);

    await auth.signOut();
    expect((await auth.watch().first).status, AuthStatus.signedOut);
  });
}
