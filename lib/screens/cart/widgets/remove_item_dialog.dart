import 'package:flutter/material.dart';

/// Confirmation dialog asking the user to confirm cart item removal.
class RemoveItemDialog extends StatelessWidget {
  final String productName;

  const RemoveItemDialog({
    super.key,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Remove from Cart'),
      content: Text(
        'Are you sure you want to remove "$productName" from your shopping cart?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}
