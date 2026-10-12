import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrandBanner extends StatelessWidget {
  final String? bannerUrl;

  const BrandBanner({
    super.key,
    this.bannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBanner = bannerUrl != null && bannerUrl!.isNotEmpty;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        child: hasBanner
            ? CachedNetworkImage(
                imageUrl: bannerUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(theme),
              )
            : _buildPlaceholder(theme),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      child: Center(
        child: Icon(
          Icons.watch,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );
  }
}