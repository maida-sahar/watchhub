// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';

class EmptyAddressWidget extends StatelessWidget {
  final VoidCallback onAddAddress;

  const EmptyAddressWidget({
    super.key,
    required this.onAddAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Addresses',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please add a shipping address to proceed with your checkout.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddAddress,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
