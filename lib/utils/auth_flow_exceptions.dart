/// Typed exceptions for the role/session-resolution flow.
///
/// These are deliberately distinct from FirebaseAuthException (which
/// AuthService/AuthRepository already handle for sign-in/sign-up). These
/// cover everything that can go wrong *after* Firebase Auth succeeds,
/// while resolving the Firestore profile and deciding where to navigate.
library auth_flow_exceptions;

/// Firestore has no `users/{uid}` document for an authenticated Firebase
/// user. Can happen if account creation was interrupted, or the document
/// was manually deleted.
class MissingProfileException implements Exception {
  final String uid;
  const MissingProfileException(this.uid);

  @override
  String toString() => 'MissingProfileException: no profile found for $uid';
}

/// A `users/{uid}` document exists but its `role` field is null, empty,
/// or not one of the two supported roles (`UserRole.customer` /
/// `UserRole.admin` in `models/user_model.dart`).
class UnknownRoleException implements Exception {
  final String? rawValue;
  const UnknownRoleException(this.rawValue);

  @override
  String toString() =>
      'UnknownRoleException: role "$rawValue" is not a recognized WatchHub role.';
}

/// `users/{uid}.isActive == false`. The account exists but has been
/// disabled (e.g. by an admin) and must be force-logged-out.
class AccountDisabledException implements Exception {
  const AccountDisabledException();

  static const String userMessage =
      'Your account has been disabled. Please contact support.';

  @override
  String toString() => 'AccountDisabledException';
}

/// FirebaseAuth reports a user, but the ID token / session is no longer
/// valid (e.g. token revoked, password changed elsewhere). Distinct from
/// "no user at all" (unauthenticated) so the UI can optionally show a
/// "session expired, please log in again" message instead of a blank
/// login screen.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'SessionExpiredException';
}

/// Any network/connectivity failure while resolving the profile. Kept
/// separate so the splash screen can offer a "Retry" action instead of
/// silently bouncing the user to Login (which would be misleading if
/// they *are* logged in but just offline).
class ProfileFetchNetworkException implements Exception {
  final Object cause;
  const ProfileFetchNetworkException(this.cause);

  @override
  String toString() => 'ProfileFetchNetworkException: $cause';
}