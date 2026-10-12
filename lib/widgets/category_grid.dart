import 'package:flutter/material.dart';

import 'package:watch_hub/models/category_model.dart';
import 'category_card.dart';

/// Responsive [GridView.builder] wrapper that lays out [categories] as
/// [CategoryCard]s.
///
/// Column count adapts to available width:
/// • < 600px  (mobile)  → 2 columns
/// • < 1000px (tablet)  → 3 columns
/// • >= 1000px (desktop) → 4 columns
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onCategoryTap;

  /// Exposed as a static helper so [CategoryShimmer] (which renders
  /// before any grid exists) can mirror the same column count.
  static int columnsForWidth(double width) {
    if (width >= 1000) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = columnsForWidth(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              onTap: () => onCategoryTap(category),
            );
          },
        );
      },
    );
  }
}