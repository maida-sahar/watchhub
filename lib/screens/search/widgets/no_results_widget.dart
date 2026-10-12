import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';

class NoResultsWidget extends StatelessWidget {
  final VoidCallback onResetFilters;

  const NoResultsWidget({
    super.key,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 72, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'No Products Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any matches for your search or filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: onResetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}