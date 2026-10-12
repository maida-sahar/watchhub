import 'package:flutter/material.dart';

import '../../../models/product_model.dart';
import '../../products/widgets/product_card.dart';

/// Card item for search result listings with full imagery and actions.
class SearchResultCard extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserProductCard(
      product: product,
      onTap: onTap,
    );
  }
}