import 'package:flutter/material.dart';

/// A labeled Material 3 switch representing a category's active state.
///
/// Purely presentational — it does not call [CategoryProvider] itself.
/// The parent screen owns the async call (e.g. `toggleCategoryStatus`)
/// and passes the result back in through [value]; this widget just
/// renders the current state and reports taps via [onChanged].
class CategoryStatusSwitch extends StatelessWidget {
  const CategoryStatusSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isBusy = false,
  });

  /// Whether the category is currently active.
  final bool value;

  /// Called with the new desired value when the switch is toggled.
  /// The parent is responsible for calling the provider and reverting
  /// the switch (by not changing [value]) if the call fails.
  final ValueChanged<bool> onChanged;

  /// When true, disables interaction and shows a small progress
  /// indicator instead of the switch thumb label, e.g. while an async
  /// status update is in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = value ? 'Active' : 'Inactive';
    final labelColor = value
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        if (isBusy)
          const SizedBox(
            width: 32,
            height: 20,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Switch(
            value: value,
            onChanged: onChanged,
          ),
      ],
    );
  }
}