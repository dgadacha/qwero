/// État d'authentification, tel que l'interface a besoin de le connaître.
enum AuthStatus {
  /// Rien n'est encore déterminé : premier chargement.
  unknown,

  /// Personne n'est connecté.
  signedOut,

  /// Connecté, mais le profil de jeu n'existe pas encore (§65, étape compte).
  needsProfile,

  /// Connecté, profil complet.
  ready,
}

class AuthState {
  const AuthState({required this.status, this.userId, this.email});

  const AuthState.unknown() : status = AuthStatus.unknown, userId = null, email = null;

  final AuthStatus status;
  final String? userId;
  final String? email;
}

/// Contrat d'authentification.
///
/// La création du profil de jeu ne se fait pas ici : elle passe par une Cloud
/// Function, seule capable de réserver un pseudo de façon atomique (§164).
abstract interface class AuthRepository {
  Stream<AuthState> watch();

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  /// Compte sans identifiants, pour essayer l'application (§65).
  Future<void> signInAnonymously();

  /// Crée le profil de jeu et réserve le pseudo.
  Future<void> createProfile({
    required String username,
    required String displayName,
    required String timezone,
    required String locale,
  });

  Future<void> signOut();
}

/// Erreur d'authentification, déjà rédigée pour le joueur.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
