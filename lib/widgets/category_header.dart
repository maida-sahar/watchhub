import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:watch_hub/models/category_model.dart';

/// Displays the category's icon and name, laid out to visually overlap
/// the bottom of [CategoryBanner] (a common "avatar overlapping cover
/// image" pattern), giving the header a modern, layered feel.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildIcon(theme),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                category.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Negative margin effect achieved by the parent's layout — this
      // widget sits at the header's top, transform-shifted upward so it
      // overlaps the banner above it.
      transform: Matrix4.translationValues(0, -28, 0),
      child: ClipOval(
        child: category.iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: category.iconUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.watch_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.watch_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}