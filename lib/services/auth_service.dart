import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Anonymous session helper.
///
/// Firestore rules for this portfolio app are public, so a failed anonymous
/// sign-in does not block the workshop tools.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Future<User?> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e, st) {
      debugPrint('Anonymous auth skipped: $e\n$st');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
