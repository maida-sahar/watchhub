import 'package:flutter/material.dart';

class ProductStockStatus extends StatelessWidget {
  final int stock;
  final int minStock;
  final int soldCount;

  const ProductStockStatus({
    super.key,
    required this.stock,
    this.minStock = 5,
    this.soldCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;
    final bool isLowStock = stock > 0 && stock <= minStock;

    Color statusColor = Colors.green.shade700;
    String statusText = 'In Stock ($stock available)';
    IconData statusIcon = Icons.check_circle_outline;

    if (isOutOfStock) {
      statusColor = Colors.red.shade700;
      statusText = 'Currently Out of Stock';
      statusIcon = Icons.highlight_off;
    } else if (isLowStock) {
      statusColor = Colors.orange.shade800;
      statusText = 'Only $stock left in stock!';
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (soldCount > 0) ...[
            Text(
              '$soldCount Sold',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}