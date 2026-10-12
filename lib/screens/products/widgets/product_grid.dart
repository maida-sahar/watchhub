import 'package:flutter/material.dart';
import 'package:watch_hub/models/product_model.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;

  /// When `true`, the grid sizes itself to its content instead of
  /// expanding to fill its parent — needed when embedding this grid
  /// inside another scrollable (e.g. a category details page that also
  /// shows a banner/header above the grid). Defaults to `false` so
  /// existing callers that place this inside a `Sliver`/bounded-height
  /// parent (e.g. the Product catalogue screen) keep their current
  /// scrolling behavior unchanged.
  final bool shrinkWrap;

  /// Scroll physics override, used together with [shrinkWrap] so the
  /// grid doesn't fight its parent scrollable for scroll gestures.
  final ScrollPhysics? physics;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 1100) {
      crossAxisCount = 4;
    } else if (screenWidth >= 700) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return UserProductCard(
          product: product,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}