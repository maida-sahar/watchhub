import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/brand_model.dart';

class AdminBrandCard extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onFeaturedToggle;
  final ValueChanged<bool> onActiveToggle;

  const AdminBrandCard({
    super.key,
    required this.brand,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onFeaturedToggle,
    required this.onActiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brand.bannerUrl != null && brand.bannerUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: brand.bannerUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: brand.logoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (brand.country != null && brand.country!.isNotEmpty)
                        Text(
                          'Country: ${brand.country}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (brand.website != null && brand.website!.isNotEmpty)
                        Text(
                          brand.website!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        'Order: ${brand.displayOrder}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: onTap,
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Edit Brand',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete Brand',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Featured: '),
                    Switch(
                      value: brand.isFeatured,
                      onChanged: onFeaturedToggle,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Active: '),
                    Switch(
                      value: brand.isActive,
                      onChanged: onActiveToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}