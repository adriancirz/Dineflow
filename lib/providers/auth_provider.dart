import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firebase_providers.dart';

/// Stream of Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Stream of the currently logged-in user's Firestore document
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return Stream.value(null);
  }

  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromFirestore(snapshot);
  });
});

/// Auth Controller state
class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});
}

/// Riverpod 3 Notifier
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    final auth = ref.read(firebaseAuthProvider);
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect password or email.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      } else {
        message = e.message ?? message;
      }
      state = AuthState(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AuthState(isLoading: true);
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signOut();
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
