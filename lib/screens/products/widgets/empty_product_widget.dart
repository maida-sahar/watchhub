import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';

class EmptyProductWidget extends StatelessWidget {
  final VoidCallback onReset;

  const EmptyProductWidget({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_off_outlined, size: 72, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'No Products Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text('We couldn\'t find any watches matching your criteria.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}