import 'package:flutter/material.dart';

import 'widgets/most_wishlisted_products.dart';
import 'widgets/wishlist_chart_placeholder.dart';
import 'widgets/wishlist_statistics_card.dart';

/// Screen providing WatchHub administrators with analytical insights into user wishlists.
class WishlistAnalyticsScreen extends StatelessWidget {
  const WishlistAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh analytics logic
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                final items = const [
                  WishlistStatisticsCard(
                    title: 'Total Saved Items',
                    value: '1,420',
                    icon: Icons.favorite_outline,
                    color: Colors.redAccent,
                  ),
                  WishlistStatisticsCard(
                    title: 'Active Users',
                    value: '385',
                    icon: Icons.people_outline,
                    color: Colors.blueAccent,
                  ),
                  WishlistStatisticsCard(
                    title: 'Avg. Items / User',
                    value: '3.6',
                    icon: Icons.bar_chart_outlined,
                    color: Colors.amber,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: items
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return Column(
                  children: items
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Wishlist Trends',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const WishlistChartPlaceholder(),
            const SizedBox(height: 24),
            Text(
              'Most Wishlisted Watches',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const MostWishlistedProducts(),
          ],
        ),
      ),
    );
  }
}