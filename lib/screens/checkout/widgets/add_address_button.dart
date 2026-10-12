import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';

class AddAddressButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddAddressButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClayCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        borderRadius: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_location_alt_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Add New Address',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
