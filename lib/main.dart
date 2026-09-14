import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/backend/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Sans le mode Firebase, l'initialisation ne fait rien : l'application
  // démarre sur les données mockées.
  await FirebaseInit.ensure();
  runApp(const ProviderScope(child: QweroApp()));
}
