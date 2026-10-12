import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:watch_hub/models/category_model.dart';

/// Large rounded banner shown at the top of [CategoryDetailsScreen].
///
/// Wrapped in a [Hero] using the SAME tag as the category card on the
/// listing screen (`category-image-{id}`), so tapping a category
/// animates its image seamlessly into this banner. Falls back to
/// [CategoryModel.bannerUrl] when available, using [CategoryModel.imageUrl]
/// only as a fallback if no banner image was set — the banner slot is
/// intentionally distinct from the listing thumbnail.
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({super.key, required this.category, this.height = 220});

  final CategoryModel category;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl =
        category.bannerUrl.isNotEmpty ? category.bannerUrl : category.imageUrl;

    return Hero(
      tag: 'category-image-${category.id}',
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) =>
                      _buildPlaceholder(theme),
                )
              else
                _buildPlaceholder(theme),
              // Subtle gradient so a back button / title placed on top by
              // the parent screen stays legible over bright images.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.watch_outlined,
        size: 56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}