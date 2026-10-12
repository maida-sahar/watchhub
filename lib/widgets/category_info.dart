import 'package:flutter/material.dart';

import 'package:watch_hub/models/category_model.dart';

/// Displays the category's description underneath [CategoryHeader].
///
/// Falls back to a neutral placeholder sentence when the admin left
/// the description empty, so the layout never shows a blank gap.
class CategoryInfo extends StatelessWidget {
  const CategoryInfo({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = category.description.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this category',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasDescription
                ? category.description
                : 'No description provided for this category yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasDescription
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}