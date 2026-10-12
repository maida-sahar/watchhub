import 'package:flutter/material.dart';

/// Confirmation dialog asking the user to confirm item removal.
class RemoveConfirmationDialog extends StatelessWidget {
  final String productName;

  const RemoveConfirmationDialog({
    super.key,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove from Wishlist'),
      content: Text(
        'Are you sure you want to remove "$productName" from your wishlist?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}