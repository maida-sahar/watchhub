import 'package:flutter/material.dart';

/// Shown in place of the category grid when
/// `CategoryProvider.activeCategories` is empty after a successful
/// load (i.e. genuinely no active categories exist yet, as opposed to
/// a loading or error state).
class EmptyCategoryWidget extends StatelessWidget {
  const EmptyCategoryWidget({
    super.key,
    required this.onRefresh,
    this.message = 'No Categories Available',
  });

  /// Called when the user taps the "Refresh" button.
  final VoidCallback onRefresh;

  /// The message shown under the icon.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New categories will appear here as soon as they are added.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}