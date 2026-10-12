import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/auth_status.dart';
import '../../providers/auth_provider.dart';

/// Shown for the two failure modes that should NOT silently dump the
/// user on the Login screen, because logging in again won't fix them:
///   - MissingProfileException  -> Firestore doc missing for a valid
///     Firebase user; re-entering credentials changes nothing.
///   - UnknownRoleException     -> role field is corrupt/unrecognized;
///     same reasoning.
///   - Network failures         -> offers Retry instead of assuming the
///     user is logged out.
///
/// (Disabled-account and session-expired cases are handled upstream by
/// AuthProvider, which force-signs-out and routes straight to Login —
/// they never reach this screen.)
class AuthErrorScreen extends StatelessWidget {
  const AuthErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                describeAuthFailure(auth.authFailureReason),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => auth.checkUserRole(),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(
                        AppRoutes.login, (route) => false),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}