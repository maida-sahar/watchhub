import 'package:flutter/material.dart';
import '../../../models/cart_model.dart';
import 'cart_item_card.dart';
import 'cart_price_card.dart';


/// A scrollable list displaying cart items and the summary pricing card.
class CartList extends StatelessWidget {
  final List<CartModel> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final Function(CartModel) onRemoveItem;
  final Function(CartModel, int) onQuantityChanged;
  final Function(String) isItemProcessing;

  const CartList({
    super.key,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.onRemoveItem,
    required this.onQuantityChanged,
    required this.isItemProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1, // +1 for the CartPriceCard at the end
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Render the pricing summary card at the end of the list
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            child: CartPriceCard(
              subtotal: subtotal,
              discount: discount,
              grandTotal: grandTotal,
              itemsCount: items.fold(0, (sum, item) => sum + item.quantity),
            ),
          );
        }

        final item = items[index];
        final processing = isItemProcessing(item.id);

        return CartItemCard(
          item: item,
          isProcessing: processing,
          onRemove: () => onRemoveItem(item),
          onQuantityChanged: (newQty) => onQuantityChanged(item, newQty),
        );
      },
    );
  }
}
