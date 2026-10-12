import 'package:flutter/material.dart';

class ProductActions extends StatelessWidget {
  final bool isOutOfStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback onToggleWishlist;
  final bool isWishlisted;

  const ProductActions({
    super.key,
    required this.isOutOfStock,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onToggleWishlist,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Wishlist Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : Colors.grey.shade700,
                ),
                onPressed: onToggleWishlist,
              ),
            ),
            const SizedBox(width: 12),

            // Add To Cart Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                    color: isOutOfStock ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: isOutOfStock ? null : onAddToCart,
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: const Text(
                  'Add To Cart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Buy Now Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isOutOfStock ? null : onBuyNow,
                icon: const Icon(Icons.flash_on, size: 20),
                label: const Text(
                  'Buy Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}