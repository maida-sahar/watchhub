import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth]. Owns ONLY Firebase Authentication
/// concerns — no Firestore, no Google Sign-In. Keeping this narrow makes
/// it trivially mockable in unit tests.
class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Emits whenever the signed-in user changes (login/logout/token refresh).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs out of Firebase only. Google session sign-out is handled
  /// separately by [GoogleSignInService] and orchestrated by the repository.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    await _firebaseAuth.currentUser?.updateDisplayName(name);
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return _firebaseAuth.signInWithCredential(credential);
  }
}