import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/widgets/gradient_button.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

/// Password-reset request screen matching Clean Light design.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.forgotPassword(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        'Password reset email sent. Check your inbox.',
        isError: false,
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Could not send reset email.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- Top Bar ----------------
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColors.iconPrimary,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 32),

                // ---------------- Header Text ----------------
                Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the email associated with your account and we'll send you a link to reset your password.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ---------------- Email Input Field ----------------
                Text(
                  'EMAIL',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (_) => _handleResetPassword(),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'fazurrehman@gmail.com',
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 36),

                // ---------------- Reset Button ("SEND RESET LINK") ----------------
                GradientButton(
                  text: 'SEND RESET LINK',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleResetPassword,
                ),
                const SizedBox(height: 28),

                // ---------------- Back to Login ----------------
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Back to Login',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}