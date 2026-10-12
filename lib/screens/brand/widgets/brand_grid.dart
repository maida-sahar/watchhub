import 'package:flutter/material.dart';
import 'package:watch_hub/models/brand_model.dart';
import 'package:watch_hub/screens/brand/widgets/brand_card.dart';


class BrandGrid extends StatelessWidget {
  final List<BrandModel> brands;
  final Function(BrandModel) onBrandTap;

  const BrandGrid({
    super.key,
    required this.brands,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: brands.length,
          itemBuilder: (context, index) {
            final brand = brands[index];
            return UserBrandCard(
              brand: brand,
              onTap: () => onBrandTap(brand),
            );
          },
        );
      },
    );
  }
}