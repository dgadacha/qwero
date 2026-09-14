import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/backend/firebase_init.dart';
import 'auth_repository.dart';

/// Authentification Firebase.
///
/// L'état combine deux sources : la session Firebase Auth, et l'existence du
/// document de profil. Tant que le second manque, le joueur est connecté mais
/// n'a pas encore de pseudo — c'est l'étape « compte » de l'onboarding.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: FirebaseInit.region);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<AuthState> watch() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(const AuthState(status: AuthStatus.signedOut));
      }
      // Le profil peut apparaître juste après la création de compte : on suit
      // le document plutôt que de le lire une fois.
      return _db.collection('users').doc(user.uid).snapshots().map(
            (snapshot) => AuthState(
              status: snapshot.exists ? AuthStatus.ready : AuthStatus.needsProfile,
              userId: user.uid,
              email: user.email,
            ),
          );
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_readable(error));
    }
  }

  @override
  Future<void> register({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_readable(error));
    }
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_readable(error));
    }
  }

  @override
  Future<void> createProfile({
    required String username,
    required String displayName,
    required String timezone,
    required String locale,
  }) async {
    try {
      await _functions.httpsCallable('createAccount').call<void>({
        'username': username,
        'displayName': displayName,
        'timezone': timezone,
        'locale': locale,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthException(error.message ?? 'La création du compte a échoué.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Les codes d'erreur Firebase ne sont pas montrables tels quels.
  String _readable(FirebaseAuthException error) => switch (error.code) {
        'invalid-email' => "Cette adresse e-mail n'est pas valide.",
        'user-disabled' => 'Ce compte est désactivé.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Adresse e-mail ou mot de passe incorrect.',
        'email-already-in-use' => 'Un compte existe déjà avec cette adresse.',
        'weak-password' => 'Choisis un mot de passe un peu plus solide.',
        'network-request-failed' => 'Pas de connexion. Réessaie dans un instant.',
        'too-many-requests' => 'Trop de tentatives. Réessaie dans quelques minutes.',
        'operation-not-allowed' =>
          "Ce mode de connexion n'est pas activé sur le projet Firebase.",
        _ => 'La connexion a échoué.',
      };
}
