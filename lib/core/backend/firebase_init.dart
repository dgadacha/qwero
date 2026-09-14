import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'backend_mode.dart';

/// Initialisation Firebase.
///
/// Les options viennent de `firebase_options.dart`, généré par
/// `flutterfire configure`. Tant que ce fichier n'existe pas, l'application
/// reste en mode mocké (§125) : le prototype ne dépend pas d'un projet.
abstract final class FirebaseInit {
  static bool _done = false;

  static Future<void> ensure() async {
    if (_done || !Backend.isFirebase) return;

    await Firebase.initializeApp();

    if (Backend.useEmulators) {
      const host = Backend.emulatorHost;
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFunctions.instanceFor(region: region)
          .useFunctionsEmulator(host, 5001);
      debugPrint('QUEST : émulateurs Firebase sur $host');
    }

    _done = true;
  }

  /// Région des Cloud Functions, alignée sur `config.ts`.
  static const region = 'europe-west1';
}
