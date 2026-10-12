import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/google_signin_service.dart';
import '../utils/auth_flow_exceptions.dart';

/// Repository layer for authentication + user profile concerns.
///
/// This is the ONLY place that orchestrates [AuthService],
/// [FirestoreService], and [GoogleSignInService] together (e.g. "create a
/// Firebase account, then also write the Firestore profile"). AuthProvider
/// depends only on this class -- never on the individual services
/// directly -- per the Repository Pattern.
class AuthRepository {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final GoogleSignInService _googleSignInService;

  AuthRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
    GoogleSignInService? googleSignInService,
  }) {
    // Assigned in the body (not the initializer list) so
    // _googleSignInService can reuse the exact same _authService instance
    // instead of constructing a second, redundant one.
    _authService = authService ?? AuthService();
    _firestoreService = firestoreService ?? FirestoreService();
    _googleSignInService =
        googleSignInService ?? GoogleSignInService(authService: _authService);
  }

  // ---------------------------------------------------------------
  // Existing auth flows (email/password, Google, password reset)
  // ---------------------------------------------------------------

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  /// Creates the Firebase account, sets the display name, and writes the
  /// initial `users/{uid}` Firestore document with `role: customer`.
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    await _authService.updateDisplayName(name);

    final newUser = UserModel.newCustomer(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
    );
    await _firestoreService.createUserDocument(newUser);
    return newUser;
  }

  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Signs in with Google and makes sure a Firestore profile exists
  /// (creating one with `role: customer` on first-ever Google sign-in).
  Future<User> signInWithGoogle() async {
    final credential = await _googleSignInService.signInWithGoogle();
    final user = credential.user!;
    await ensureCustomerProfileExists(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  /// Signs out of both Google and Firebase.
  Future<void> signOut() async {
    await _googleSignInService.signOut();
    await _authService.signOut();
  }

  // ---------------------------------------------------------------
  // Role-based auth / session additions
  // ---------------------------------------------------------------

  /// Fetches the `users/{uid}` profile.
  ///
  /// Throws:
  ///   - [MissingProfileException] if no document exists for [uid].
  ///   - [ProfileFetchNetworkException] on any other read failure.
  Future<UserModel> getCurrentUserProfile(String uid) async {
    try {
      final profile = await _firestoreService.getUserDocument(uid);
      if (profile == null) {
        throw MissingProfileException(uid);
      }
      return profile;
    } on MissingProfileException {
      rethrow;
    } catch (e) {
      throw ProfileFetchNetworkException(e);
    }
  }

  /// Resolves the raw role string for [uid]. Validates it against the two
  /// supported roles declared on `UserRole` in `models/user_model.dart`.
  ///
  /// Throws [MissingProfileException], [UnknownRoleException], or
  /// [ProfileFetchNetworkException].
  Future<String> getUserRole(String uid) async {
    final profile = await getCurrentUserProfile(uid);
    _assertKnownRole(profile.role);
    return profile.role;
  }

  Future<bool> isUserActive(String uid) async {
    final profile = await getCurrentUserProfile(uid);
    return profile.isActive;
  }

  /// Convenience used by AuthProvider: one Firestore read that returns
  /// role + active flag together, with the role already validated.
  ///
  /// Throws [MissingProfileException], [UnknownRoleException], or
  /// [ProfileFetchNetworkException].
  Future<UserModel> getRoleAndActiveStatus(String uid) async {
    final profile = await getCurrentUserProfile(uid);
    _assertKnownRole(profile.role);
    return profile;
  }

  void _assertKnownRole(String role) {
    if (role != UserRole.customer && role != UserRole.admin) {
      throw UnknownRoleException(role);
    }
  }

  /// Used by the Google Sign-In flow: creates the `users/{uid}` document
  /// with default `role: customer` if (and only if) it does not already
  /// exist. Idempotent -- safe to call on every Google login.
  Future<void> ensureCustomerProfileExists({
    required String uid,
    required String? name,
    required String? email,
    required String? photoUrl,
  }) async {
    try {
      final exists = await _firestoreService.userDocumentExists(uid);
      if (exists) return;

      final newUser = UserModel.newCustomer(
        uid: uid,
        name: name ?? '',
        email: email ?? '',
        phone: '',
        photoUrl: photoUrl ?? '',
      );
      await _firestoreService.createUserDocument(newUser);
    } catch (e) {
      throw ProfileFetchNetworkException(e);
    }
  }

  /// True when FirebaseAuth still reports a user AND that user's ID
  /// token can still be silently refreshed. Used to distinguish
  /// "genuinely logged out" from "session/token expired" during auto
  /// login, per the SESSION MANAGEMENT requirement.
  Future<bool> hasValidSession(User firebaseUser) async {
    try {
      await firebaseUser.getIdToken();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }
}
