import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Wraps a screen and enforces that only the given [allowedRole] can see
/// it. If the currently signed-in user's role doesn't match, the guard
/// redirects them to *their own* home instead of showing the screen --
/// e.g. an admin who somehow navigates to a customer route is bounced to
/// the Admin Dashboard, and vice versa, exactly per the ROUTE PROTECTION
/// requirement ("Admin should NOT enter Customer Home").
///
/// This is defense-in-depth on top of [AppRouter.onGenerateRoute]
/// already refusing to build the widget in the first place -- keep both
/// layers, since `Navigator.push` can be called directly from anywhere
/// in the tree, bypassing named-route generation.
class RouteGuard extends StatelessWidget {
  /// One of `UserRole.customer` / `UserRole.admin` (from
  /// `models/user_model.dart`).
  final String allowedRole;
  final Widget child;

  const RouteGuard({
    super.key,
    required this.allowedRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.currentRole;

    if (role == null) {
      // Session dropped (e.g. disabled mid-session) while this route was
      // on screen -- bounce to Login rather than show a broken page.
      return _Redirect(routeName: AppRoutes.login);
    }

    if (role != allowedRole) {
      final fallback = role == UserRole.admin
          ? AppRoutes.adminDashboard
          : AppRoutes.customerHome;
      return _Redirect(routeName: fallback);
    }

    return child;
  }
}

/// Performs a post-frame redirect. Built as its own tiny widget (rather
/// than calling Navigator inside `build`) because triggering navigation
/// during a build phase throws in Flutter.
class _Redirect extends StatefulWidget {
  final String routeName;
  const _Redirect({required this.routeName});

  @override
  State<_Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<_Redirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.routeName,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}