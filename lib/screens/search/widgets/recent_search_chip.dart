import 'package:flutter/material.dart';

class RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecentSearchChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      onPressed: onTap,
      avatar: const Icon(Icons.history, size: 16),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(color: Colors.grey.shade300),
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 14),
    );
  }
}