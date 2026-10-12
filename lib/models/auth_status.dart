/// Drives every navigation decision in the app. AuthProvider is the single
/// owner of this value; screens only ever *read* it (via Consumer/Selector)
/// and never set it directly.
enum AuthStatus {
  /// Provider has not finished checking FirebaseAuth.currentUser yet.
  /// Splash screen stays visible in this state.
  uninitialized,

  /// Actively resolving the Firestore profile / role for a Firebase user
  /// that is already signed in (auto-login or post-login flow).
  authenticating,

  /// Firebase session valid, Firestore profile found, role resolved,
  /// isActive == true. `ResolvedSession.role` is guaranteed non-null here.
  authenticatedCustomer,
  authenticatedAdmin,

  /// No FirebaseAuth.currentUser -> Login screen.
  unauthenticated,

  /// A distinguishable, user-facing failure. `authFailureReason` on
  /// AuthProvider carries the reason (see AuthFailureReason) so the UI
  /// can show the right message without re-deriving it.
  error,
}

/// Fine-grained reason behind [AuthStatus.error], so the UI/navigation
/// layer can react differently (e.g. disabled account -> route to Login;
/// network failure -> show retry button and stay on an error screen).
enum AuthFailureReason {
  missingProfileDocument,
  unknownRole,
  accountDisabled,
  sessionExpired,
  network,
  unknown,
}

/// User-facing copy for each [AuthFailureReason]. Shared by AuthProvider
/// (for login/Google-login SnackBars) and AuthErrorScreen, so the message
/// for a given reason is defined exactly once.
String describeAuthFailure(AuthFailureReason? reason) {
  switch (reason) {
    case AuthFailureReason.missingProfileDocument:
      return 'We could not find your profile. Please contact support so '
          'we can restore your account.';
    case AuthFailureReason.unknownRole:
      return 'Your account role could not be recognized. Please contact '
          'support.';
    case AuthFailureReason.network:
      return 'No internet connection. Please check your network and try '
          'again.';
    case AuthFailureReason.accountDisabled:
      return 'Your account has been disabled. Please contact support.';
    case AuthFailureReason.sessionExpired:
      return 'Your session has expired. Please log in again.';
    case AuthFailureReason.unknown:
    case null:
      return 'Something went wrong while signing you in. Please try '
          'again.';
  }
}

/// Small immutable bundle describing the resolved user, kept on
/// AuthProvider so screens don't need to re-fetch anything to decide
/// where to route.
///
/// [role] is one of the string constants defined on `UserRole` in
/// `models/user_model.dart` (`UserRole.customer` / `UserRole.admin`) --
/// deliberately a `String`, not a separate enum, so there is only ever
/// one type in the app representing "role" (the one UserModel already
/// defines).
class ResolvedSession {
  final String uid;
  final String role;
  final bool isActive;

  const ResolvedSession({
    required this.uid,
    required this.role,
    required this.isActive,
  });
}
