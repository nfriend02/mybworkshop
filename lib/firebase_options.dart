import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase options for the mybworkshop web app.
///
/// Web API keys are public client identifiers. dotenv (`.env` / Netlify env)
/// overrides these values when it is present and complete.
class DefaultFirebaseOptions {
  static const FirebaseOptions mybworkshop = FirebaseOptions(
    apiKey: 'AIzaSyCFxQOwdbozBzoywh2vlxX0f1j6Gg7bIVQ',
    appId: '1:631186762504:web:954ac57f9c4085217a9abd',
    messagingSenderId: '631186762504',
    projectId: 'mybworkshop',
    authDomain: 'mybworkshop.firebaseapp.com',
    storageBucket: 'mybworkshop.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (!dotenv.isInitialized) return mybworkshop;

    final apiKey = dotenv.env['FIREBASE_API_KEY']?.trim();
    final appId = dotenv.env['FIREBASE_APP_ID']?.trim();
    final messagingSenderId =
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim();
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim();

    final envReady = apiKey != null &&
        apiKey.isNotEmpty &&
        !apiKey.startsWith('your_') &&
        appId != null &&
        appId.isNotEmpty &&
        messagingSenderId != null &&
        messagingSenderId.isNotEmpty &&
        projectId != null &&
        projectId.isNotEmpty;

    if (!envReady) return mybworkshop;

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _or(dotenv.env['FIREBASE_AUTH_DOMAIN'], mybworkshop.authDomain),
      storageBucket:
          _or(dotenv.env['FIREBASE_STORAGE_BUCKET'], mybworkshop.storageBucket),
      measurementId: _optional(dotenv.env['FIREBASE_MEASUREMENT_ID']),
    );
  }

  static bool get isConfigured => currentPlatform.projectId.isNotEmpty;

  static String _or(String? value, String? fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback ?? '';
    return trimmed;
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
