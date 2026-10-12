import 'package:flutter/material.dart';

import '../../../models/category_model.dart';

/// A Material 3 card summarizing a single [CategoryModel] in the Admin
/// Panel's category list.
///
/// Purely presentational: all actions (view/edit/delete/status toggle)
/// are reported upward via callbacks. This widget never touches
/// [CategoryProvider] or Firebase directly.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.isTogglingStatus = false,
  });

  final CategoryModel category;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStatus;
  final bool isTogglingStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted = _formatDate(category.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(theme),
              const SizedBox(width: 12),
              Expanded(child: _buildDetails(context, theme, dateFormatted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        height: 72,
        child: category.imageUrl.isNotEmpty
            ? Image.network(
                category.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

  Widget _buildDetails(
    BuildContext context,
    ThemeData theme,
    String dateFormatted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusChip(theme),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          category.description.isNotEmpty
              ? category.description
              : 'No description provided.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildMetaChip(theme, Icons.sort, 'Order ${category.displayOrder}'),
            _buildMetaChip(theme, Icons.calendar_today_outlined, dateFormatted),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Switch(
              value: category.isActive,
              onChanged: isTogglingStatus ? null : onToggleStatus,
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'View',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: onView,
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final isActive = category.isActive;
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetaChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Formats [date] as `dd MMM yyyy` (e.g. "19 Jul 2026") without pulling
  /// in the `intl` package, keeping this widget dependency-light.
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }
}