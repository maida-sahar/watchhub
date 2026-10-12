import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_routes.dart';
import '../models/auth_status.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/auth_exception_mapper.dart';
import '../utils/auth_flow_exceptions.dart';

/// Single source of truth for auth state across the whole app.
///
/// Owns two related-but-distinct things:
///   1. The email/password + Google sign-in/sign-up/forgot-password
///      flows (`login`, `register`, `googleLogin`, `forgotPassword`),
///      talked to directly by the Login/Signup/Forgot-Password screens.
///   2. Role resolution, auto login, session restoration, and the
///      "where should the app navigate right now" decision
///      (`initializeAuth`, `restoreSession`, `navigateBasedOnRole`),
///      driven by the Splash screen and consumed by [RouteGuard].
///
/// Screens only ever talk to this provider -- never to AuthRepository or
/// any service directly -- and only this provider decides navigation
/// destinations; screens just push wherever it tells them to.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // ---------------------------------------------------------------
  // Email/password + Google flow state (login, register, etc.)
  // ---------------------------------------------------------------

  bool _isLoading = false;
  String? _errorMessage;
   String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Signs in with email/password, then immediately resolves the user's
  /// role/active status so the caller (Login screen) can navigate via
  /// [navigateBasedOnRole] as soon as this returns `true`.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await restoreSession(user);

      if (_authStatus == AuthStatus.authenticatedCustomer ||
          _authStatus == AuthStatus.authenticatedAdmin) {
        return true;
      }
      _errorMessage = describeAuthFailure(_authFailureReason);
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthExceptionMapper.fromFirebaseAuthException(e).message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new customer account. Deliberately signs the new user
  /// back out afterwards so they land on "account created, please log
  /// in" (matching the Signup screen's flow of popping back to Login)
  /// instead of silently auto-authenticating them mid-signup.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.registerWithEmailAndPassword(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await _authRepository.signOut();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthExceptionMapper.fromFirebaseAuthException(e).message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with Google (creating a default `role: customer` profile
  /// on first-ever sign-in), then resolves role/active status exactly
  /// like [login].
  Future<bool> googleLogin() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authRepository.signInWithGoogle();
      await restoreSession(user);

      if (_authStatus == AuthStatus.authenticatedCustomer ||
          _authStatus == AuthStatus.authenticatedAdmin) {
        return true;
      }
      _errorMessage = describeAuthFailure(_authFailureReason);
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthExceptionMapper.fromFirebaseAuthException(e).message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthExceptionMapper.fromFirebaseAuthException(e).message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Role-based auth / auto login / session state
  // ---------------------------------------------------------------

  AuthStatus _authStatus = AuthStatus.uninitialized;
  AuthFailureReason? _authFailureReason;
  ResolvedSession? _session;
  UserModel? _user;
  StreamSubscription<User?>? _authStateSubscription;

  AuthStatus get authStatus => _authStatus;
  AuthFailureReason? get authFailureReason => _authFailureReason;
  String? get currentRole => _session?.role;
  String? get currentUid => _session?.uid;
  UserModel? get user => _user;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticatedCustomer || _authStatus == AuthStatus.authenticatedAdmin;
  bool get isAdmin => _session?.role == UserRole.admin;
  bool get isCustomer => _session?.role == UserRole.customer;

  /// Call once, from the Splash screen. Attaches a *live* listener to
  /// `authStateChanges` (not a one-shot check) so the app both auto-logs
  /// the user in on launch AND reacts if the session dies later (token
  /// revoked, account disabled mid-session).
  Future<void> initializeAuth() async {
    _setStatus(AuthStatus.uninitialized);

    await _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (User? firebaseUser) async {
        if (firebaseUser == null) {
          _session = null;
          _user = null;
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
        await restoreSession(firebaseUser);
      },
      onError: (_) {
        _authFailureReason = AuthFailureReason.network;
        _setStatus(AuthStatus.error);
      },
    );
  }

  /// Resolves role + active status for an already-authenticated Firebase
  /// user and updates [authStatus] accordingly. Used by the
  /// [initializeAuth] listener (auto login / session restore) AND called
  /// directly from [login] / [googleLogin] right after a fresh sign-in
  /// succeeds, so the provider -- not the UI -- decides where to go next.
  Future<void> restoreSession(User firebaseUser) async {
    _setStatus(AuthStatus.authenticating);

    try {
      // Confirms the Firebase session itself (not just Firestore data)
      // is still valid -- catches revoked tokens / password changes on
      // another device.
      final sessionValid = await _authRepository.hasValidSession(firebaseUser);
      if (!sessionValid) {
        throw const SessionExpiredException();
      }

      final profile =
          await _authRepository.getRoleAndActiveStatus(firebaseUser.uid);

      if (!profile.isActive) {
        throw const AccountDisabledException();
      }

      _user = profile;

      _session = ResolvedSession(
        uid: firebaseUser.uid,
        role: profile.role,
        isActive: true,
      );

      _setStatus(
        profile.role == UserRole.admin
            ? AuthStatus.authenticatedAdmin
            : AuthStatus.authenticatedCustomer,
      );
    } on MissingProfileException {
      _authFailureReason = AuthFailureReason.missingProfileDocument;
      _setStatus(AuthStatus.error);
    } on UnknownRoleException {
      _authFailureReason = AuthFailureReason.unknownRole;
      _setStatus(AuthStatus.error);
    } on AccountDisabledException {
      _authFailureReason = AuthFailureReason.accountDisabled;
      _setStatus(AuthStatus.error);
      await logout();
    } on SessionExpiredException {
      _authFailureReason = AuthFailureReason.sessionExpired;
      _setStatus(AuthStatus.error);
      await logout();
    } on ProfileFetchNetworkException {
      _authFailureReason = AuthFailureReason.network;
      _setStatus(AuthStatus.error);
    } catch (_) {
      _authFailureReason = AuthFailureReason.unknown;
      _setStatus(AuthStatus.error);
    }
  }

  /// Re-checks the *current* session's role/active flag on demand (e.g.
  /// the "Retry" button on AuthErrorScreen).
  Future<void> checkUserRole() async {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) {
      _session = null;
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    await restoreSession(firebaseUser);
  }

  /// Pure decision function: given the current [authStatus], returns the
  /// named route the app should be on. Centralizes the
  /// "customer -> user home / admin -> admin dashboard" rule so it is
  /// defined exactly once -- only this provider decides navigation.
  String navigateBasedOnRole() {
    switch (_authStatus) {
      case AuthStatus.authenticatedCustomer:
        return AppRoutes.customerHome;
      case AuthStatus.authenticatedAdmin:
        return AppRoutes.adminDashboard;
      case AuthStatus.unauthenticated:
        return AppRoutes.login;
      case AuthStatus.error:
        // Disabled/expired sessions resolve to Login (logout() has
        // already run by the time this is read); other errors go to a
        // dedicated error/retry screen.
        return (_authFailureReason == AuthFailureReason.accountDisabled ||
                _authFailureReason == AuthFailureReason.sessionExpired)
            ? AppRoutes.login
            : AppRoutes.authError;
      case AuthStatus.uninitialized:
      case AuthStatus.authenticating:
        return AppRoutes.splash;
    }
  }

  /// Signs the user out immediately and clears local session state.
  /// Called automatically whenever [restoreSession] detects
  /// `isActive == false` or an expired session. Also safe to call
  /// directly for a normal user-initiated "Log out" action.
  Future<void> logout() async {
    _session = null;
    _user = null;
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Even if sign-out itself fails, local session state is already
      // cleared above, so the UI will still route to Login.
    }
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Alias kept for the "disabled account -> force logout" requirement
  /// so intent is clear at call sites; delegates to [logout].
  Future<void> logoutIfDisabled() => logout();

  void _setStatus(AuthStatus status) {
    _authStatus = status;
    if (status != AuthStatus.error) {
      _authFailureReason = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
