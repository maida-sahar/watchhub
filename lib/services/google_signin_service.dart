import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/auth_exception_mapper.dart';
import 'auth_service.dart';

/// Owns the Google Sign-In flow and exchanges the Google credential for a
/// Firebase [UserCredential]. Does not touch Firestore — that's the
/// repository's job, since "is this a first-time user" is a business
/// decision, not an auth-provider concern.
class GoogleSignInService {
  final GoogleSignIn _googleSignIn;
  final AuthService _authService;

  GoogleSignInService({
    GoogleSignIn? googleSignIn,
    AuthService? authService,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _authService = authService ?? AuthService();

  /// Runs the full Google -> Firebase sign-in flow.
  /// Throws [AuthException] with code `google-sign-in-cancelled` if the
  /// user dismisses the Google account picker.
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthExceptionMapper.fromCode('google-sign-in-cancelled');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _authService.signInWithCredential(credential);
  }

  /// Ends the Google session. Firebase sign-out is handled separately by
  /// [AuthService.signOut] so the repository can call both explicitly.
  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }
}