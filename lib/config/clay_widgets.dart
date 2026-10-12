import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_typography.dart';
import 'package:watch_hub/config/app_shadows.dart';

/// Soft clay‑style card with diffused shadows and subtle border.
class ClayCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isPressed;
  final List<BoxShadow>? shadows;

  const ClayCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.isPressed = false,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = shadows ?? (isPressed
        ? AppShadows.soft
        : AppShadows.medium);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// Clay‑style button – primary uses Copper Brown gradient.
class ClayButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;

  const ClayButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onPressed,
      child: ClayCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        borderRadius: 30,
        isPressed: onPressed == null,
        child: isPrimary
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(2),
                child: Center(child: child),
              )
            : child,
      ),
    );
  }
}

/// Clay‑style text field (wrapped in a clay card).
class ClayTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;

  const ClayTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 24,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: InputBorder.none,
          labelStyle: AppTypography.bodyMedium,
        ),
        style: AppTypography.bodyLarge,
      ),
    );
  }
}