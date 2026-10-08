import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service providing silent Firebase Anonymous Authentication for dine-in customers.
class AnonymousAuthService {
  final FirebaseAuth _auth;

  AnonymousAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  /// Silently signs in the customer anonymously if not already signed in.
  /// Idempotent: If a user is already signed in, returns null without re-authenticating.
  Future<UserCredential?> signInAnonymously() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null) {
      return null;
    }

    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } catch (e) {
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  /// Clears the anonymous session (e.g. after order settlement or prolonged inactivity).
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final anonymousAuthServiceProvider = Provider<AnonymousAuthService>((ref) {
  return AnonymousAuthService();
});
