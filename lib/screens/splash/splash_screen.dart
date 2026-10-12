import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';

import '../../models/auth_status.dart';
import '../../providers/auth_provider.dart';

/// First screen the app shows. Its only job is:
///   1. Kick off AuthProvider.initializeAuth() once.
///   2. Watch AuthProvider.authStatus.
///   3. As soon as status settles into a terminal state, ask the
///      provider where to go (navigateBasedOnRole()) and navigate there.
///
/// No business logic lives here — this screen never talks to Firebase,
/// FirestoreService, or AuthRepository directly, per "Only Provider
/// should decide navigation."
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guard against re-triggering on every rebuild; initializeAuth()
    // should run exactly once per app launch.
    if (!_started) {
      _started = true;
      // Deferred to post-frame so context/provider are fully mounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().initializeAuth();
      });
    }
  }

  void _navigateIfSettled(BuildContext context, AuthProvider auth) {
    const settledStates = {
      AuthStatus.authenticatedCustomer,
      AuthStatus.authenticatedAdmin,
      AuthStatus.unauthenticated,
      AuthStatus.error,
    };
    if (!settledStates.contains(auth.authStatus)) return;

    final destination = auth.navigateBasedOnRole();

    // Defer navigation to post-frame: this callback can fire mid-build
    // (Consumer rebuild) and Navigator must not be driven during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        destination,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        _navigateIfSettled(context, auth);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.watch_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'WatchHub',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'LUXURY TIMEPIECES',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please wait...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}