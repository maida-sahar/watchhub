import 'package:flutter/material.dart';
import 'package:watch_hub/models/wishlist_model.dart';

import 'wishlist_card.dart'; // <--- Required Import

class WishlistGrid extends StatelessWidget {
  final List<WishlistModel> items;
  final Function(String id, String name) onRemove;
  final Function(String productId) onTap;
  final Function(String productId) onMoveToCart;

  const WishlistGrid({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onTap,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return WishlistCard(
              item: item,
              onRemove: () => onRemove(item.id, item.productName),
              onTap: () => onTap(item.productId),
              onMoveToCart: () => onMoveToCart(item.productId),
            );
          },
        );
      },
    );
  }
}