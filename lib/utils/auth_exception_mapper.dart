import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by the repository/provider layer with an already-friendly
/// message, so the UI never needs to know about FirebaseAuthException.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Translates raw Firebase/Google error codes into clean, user-facing
/// copy. Centralizing this avoids duplicated switch-statements across
/// register/login/google-login/forgot-password flows.
class AuthExceptionMapper {
  AuthExceptionMapper._();

  static AuthException fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return const AuthException(
            'That password is too weak. Please choose a stronger one.');
      case 'email-already-in-use':
        return const AuthException(
            'An account already exists with this email.');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('Incorrect email or password.');
      case 'user-not-found':
        return const AuthException('No account found with this email.');
      case 'invalid-email':
        return const AuthException('That email address looks invalid.');
      case 'network-request-failed':
        return const AuthException(
            'Network error. Please check your connection and try again.');
      case 'too-many-requests':
        return const AuthException(
            'Too many attempts. Please wait a moment and try again.');
      case 'user-disabled':
        return const AuthException(
            'This account has been disabled. Contact support for help.');
      case 'operation-not-allowed':
        return const AuthException(
            'This sign-in method is currently disabled.');
      case 'requires-recent-login':
        return const AuthException(
            'Please log in again to complete this action.');
      default:
        return AuthException(
            e.message ?? 'Something went wrong. Please try again.');
    }
  }

  /// For non-FirebaseAuthException failures (e.g. Google Sign-In flow).
  static AuthException fromCode(String code, [String? fallback]) {
    switch (code) {
      case 'google-sign-in-cancelled':
        return const AuthException('Google sign-in was cancelled.');
      case 'firestore-write-failed':
        return const AuthException(
            'Could not save your profile. Please try again.');
      default:
        return AuthException(fallback ?? 'Something went wrong. Please try again.');
    }
  }
}