import 'package:flutter/material.dart';

class ProductRating extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  const ProductRating({
    super.key,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star, size: 12, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < averageRating.floor()
                  ? Icons.star
                  : (index < averageRating && averageRating % 1 != 0)
                      ? Icons.star_half
                      : Icons.star_border,
              size: 16,
              color: Colors.amber.shade700,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}