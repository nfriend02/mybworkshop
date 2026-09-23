import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/firebase_bootstrap.dart';

/// Entry point — Firebase init, dotenv, routing.
///
/// Developer Guidelines: every branch app exposes `main.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await bootstrapFirebase();
  runApp(MyBWorkshopApp(firebaseReady: firebaseReady));
}
