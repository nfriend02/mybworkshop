import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../firebase_options.dart';
import '../services/auth_service.dart';

/// Loads `.env` assets and initializes Firebase.
///
/// Returns whether Firestore/Auth can be used. Missing keys fall back to the
/// built-in mybworkshop options; a hard failure switches the UI to demo mode.
Future<bool> bootstrapFirebase() async {
  try {
    await dotenv.load(
      fileName: 'assets/config/app.env',
      overrideWithFiles: const ['assets/config/app_config.env'],
      isOptional: true,
    );
  } catch (e, st) {
    debugPrint('dotenv load skipped: $e\n$st');
  }

  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (Firebase.apps.isNotEmpty) {
      final existing = Firebase.app();
      if (existing.options.projectId != options.projectId) {
        await existing.delete();
      }
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    debugPrint('Firebase ready: ${options.projectId}');
    await AuthService().ensureSignedIn();
    return true;
  } catch (e, st) {
    debugPrint('Firebase init skipped/failed: $e\n$st');
    return false;
  }
}
