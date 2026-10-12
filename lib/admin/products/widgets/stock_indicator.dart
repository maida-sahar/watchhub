import 'package:flutter/material.dart';

class StockIndicator extends StatelessWidget {
  final int stock;
  final int minStock;

  const StockIndicator({
    super.key,
    required this.stock,
    required this.minStock,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String statusText;

    if (stock <= 0) {
      badgeColor = Colors.red;
      statusText = 'Out of Stock';
    } else if (stock <= minStock) {
      badgeColor = Colors.orange;
      statusText = 'Low Stock ($stock)';
    } else {
      badgeColor = Colors.green;
      statusText = 'In Stock ($stock)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}