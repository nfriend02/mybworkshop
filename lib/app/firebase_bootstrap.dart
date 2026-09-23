import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../firebase_options.dart';
import '../services/auth_service.dart';

/// Loads `.env` assets and initializes Firebase.
///
/// Returns whether Firestore/Auth can be used. Missing keys fall back to the
/// built-in mybworkshop options; a hard failure switches the UI to demo mode.
Future<bool> bootstrapFirebase() async {
  final merged = <String, String>{};
  for (final path in const [
    'assets/config/app.env',
    'assets/config/app_config.env',
  ]) {
    try {
      final raw = await rootBundle.loadString(path);
      for (final line in raw.split(RegExp(r'\r?\n'))) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final index = trimmed.indexOf('=');
        if (index <= 0) continue;
        final key = trimmed.substring(0, index).trim();
        final value = trimmed.substring(index + 1).trim();
        if (value.isEmpty && merged.containsKey(key)) continue;
        merged[key] = value;
      }
    } catch (e, st) {
      debugPrint('dotenv load ($path) skipped: $e\n$st');
    }
  }
  dotenv.testLoad(mergeWith: merged);

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
