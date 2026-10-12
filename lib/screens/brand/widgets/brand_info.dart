import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_hub/models/brand_model.dart';
import 'package:watch_hub/screens/brand/widgets/brand_statistics.dart';


class BrandInfo extends StatelessWidget {
  final BrandModel brand;
  final int totalProducts;

  const BrandInfo({
    super.key,
    required this.brand,
    this.totalProducts = 0,
  });

  Future<void> _launchWebsite(BuildContext context, String urlString) async {
    final Uri? uri = Uri.tryParse(
      urlString.startsWith('http') ? urlString : 'https://$urlString',
    );

    if (uri != null) {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            _showErrorSnackBar(context);
          }
        }
      } catch (_) {
        if (context.mounted) {
          _showErrorSnackBar(context);
        }
      }
    } else {
      _showErrorSnackBar(context);
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch website URL')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = brand.description != null && brand.description!.isNotEmpty;
    final hasCountry = brand.country != null && brand.country!.isNotEmpty;
    final hasWebsite = brand.website != null && brand.website!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Statistics Bar
        BrandStatistics(
          totalProducts: totalProducts,
          isFeatured: brand.isFeatured,
        ),
        const SizedBox(height: 24),

        // Metadata Chips (Country & Website)
        if (hasCountry || hasWebsite) ...[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (hasCountry)
                Chip(
                  avatar: Icon(
                    Icons.public,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text('Origin: ${brand.country}'),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  side: BorderSide.none,
                ),
              if (hasWebsite)
                ActionChip(
                  avatar: Icon(
                    Icons.language,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    brand.website!,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () => _launchWebsite(context, brand.website!),
                  backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Brand Description Section
        if (hasDescription) ...[
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            brand.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}