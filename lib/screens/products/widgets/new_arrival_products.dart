import 'package:flutter/material.dart';
import 'package:watch_hub/models/product_model.dart';
import 'product_card.dart';

class NewArrivalProductsSection extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;

  const NewArrivalProductsSection({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('New Arrivals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 150,
                child: UserProductCard(
                  product: products[index],
                  onTap: () => onProductTap(products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}