import 'package:flutter/material.dart';

class ProductPrice extends StatelessWidget {
  final double price;
  final double? discountPrice;
  final String currency;

  const ProductPrice({
    super.key,
    required this.price,
    this.discountPrice,
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = discountPrice != null && discountPrice! > 0 && discountPrice! < price;
    final double effectivePrice = hasDiscount ? discountPrice! : price;

    double discountPercentage = 0;
    if (hasDiscount && price > 0) {
      discountPercentage = ((price - discountPrice!) / price) * 100;
    }

    return Row(
      crossAxisAlignment: .baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$currency${effectivePrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '$currency${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              '-${discountPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}