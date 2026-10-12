import 'package:flutter/material.dart';

import '../../../models/product_model.dart';
import 'search_result_card.dart';

/// Grid display for search result items passing user ID and selection callbacks down.
class SearchResultGrid extends StatelessWidget {
  final List<ProductModel> products;
  final String currentUserId;
  final Function(ProductModel) onProductTap;

  const SearchResultGrid({
    super.key,
    required this.products,
    required this.currentUserId,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return SearchResultCard(
          product: product,
          currentUserId: currentUserId,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}