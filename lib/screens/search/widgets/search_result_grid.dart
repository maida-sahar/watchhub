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
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 768) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
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