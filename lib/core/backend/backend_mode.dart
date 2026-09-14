/// Choix de la source de données.
///
/// Le prototype mocké reste jouable sans projet Firebase : c'est ce qui permet
/// de travailler l'interface, et de faire tourner l'application sur une machine
/// qui n'a pas les fichiers de configuration Firebase.
///
/// ```bash
/// flutter run                                 # données mockées
/// flutter run --dart-define=BACKEND=firebase  # Firestore + Cloud Functions
/// flutter run --dart-define=BACKEND=firebase --dart-define=EMULATORS=true
/// ```
enum BackendMode { mock, firebase }

abstract final class Backend {
  static const _raw = String.fromEnvironment('BACKEND', defaultValue: 'mock');

  static BackendMode get mode =>
      _raw == 'firebase' ? BackendMode.firebase : BackendMode.mock;

  static bool get isFirebase => mode == BackendMode.firebase;

  /// Pointe les SDK vers les émulateurs locaux plutôt que vers la production.
  static const useEmulators = bool.fromEnvironment('EMULATORS');

  /// Hôte des émulateurs. `localhost` depuis un simulateur iOS,
  /// `10.0.2.2` depuis un émulateur Android.
  static const emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '127.0.0.1');
}
