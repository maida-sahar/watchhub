import 'package:flutter/material.dart';

/// Mock/Placeholder display list for top wishlisted products in WatchHub.
class MostWishlistedProducts extends StatelessWidget {
  const MostWishlistedProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mockTopProducts = [
      {
        'name': 'Rolex Submariner Date',
        'brand': 'Rolex',
        'category': 'Luxury',
        'count': 142,
        'image': 'https://via.placeholder.com/100',
      },
      {
        'name': 'Omega Speedmaster Professional',
        'brand': 'Omega',
        'category': 'Chronograph',
        'count': 98,
        'image': 'https://via.placeholder.com/100',
      },
      {
        'name': 'TAG Heuer Carrera',
        'brand': 'TAG Heuer',
        'category': 'Sport',
        'count': 76,
        'image': 'https://via.placeholder.com/100',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockTopProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = mockTopProducts[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.watch),
                ),
              ),
            ),
            title: Text(
              item['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item['brand']} • ${item['category']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '❤️ ${item['count']} saves',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}