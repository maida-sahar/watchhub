// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/providers/checkout_provider.dart';
import 'widgets/order_summary.dart';
import 'widgets/place_order_button.dart';

class OrderReviewScreen extends StatelessWidget {
  const OrderReviewScreen({super.key});

  void _changeAddress(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.customerShippingAddress,
      arguments: true, // Enable selector mode
    );
  }

  void _changeDeliveryMethod(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.customerDeliveryMethod);
  }

  Future<void> _placeOrder(BuildContext context) async {
    final checkoutProvider = context.read<CheckoutProvider>();

    final success = await checkoutProvider.placeOrder();

    if (context.mounted) {
      if (success) {
        // Unsubscribe and clear cart locally just in case, Firestore streams will update it
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.customerOrderSuccess,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkoutProvider.errorMessage ?? 'Failed to place order.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final checkout = checkoutProvider.currentCheckout;
    final theme = Theme.of(context);

    if (checkout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Review')),
        body: const Center(
          child: Text('No active checkout session. Please return to the Cart.'),
        ),
      );
    }

    final address = checkout.shippingAddress;
    final delivery = checkout.deliveryMethod;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Review'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: checkoutProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // --- SHIPPING ADDRESS REVIEW ---
                        _buildHeaderRow('Shipping Address', () => _changeAddress(context)),
                        const SizedBox(height: 8),
                        if (address == null)
                          _buildWarningCard('No shipping address selected.', () => _changeAddress(context))
                        else
                          ClayCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      address.fullName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        address.addressType,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${address.streetAddress}, ${address.area}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary.withOpacity(0.8),
                                  ),
                                ),
                                Text(
                                  '${address.city}, ${address.province}, ${address.country} - ${address.postalCode}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      address.phone,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // --- DELIVERY METHOD REVIEW ---
                        _buildHeaderRow('Delivery Method', () => _changeDeliveryMethod(context)),
                        const SizedBox(height: 8),
                        if (delivery == null)
                          _buildWarningCard('No delivery method selected.', () => _changeDeliveryMethod(context))
                        else
                          ClayCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 20,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        delivery.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        delivery.description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  delivery.deliveryCharge == 0.0
                                      ? 'Free'
                                      : '\$${delivery.deliveryCharge.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // --- CART ITEMS REVIEW ---
                        _buildSectionTitle('Items in Order'),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: checkout.cartItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = checkout.cartItems[index];
                            return ClayCard(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 16,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.productImage.isNotEmpty
                                        ? Image.network(
                                            item.productImage,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 60,
                                              height: 60,
                                              color: AppColors.border,
                                              child: const Icon(Icons.watch, color: AppColors.textSecondary),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: AppColors.border,
                                            child: const Icon(Icons.watch, color: AppColors.textSecondary),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${(item.discountPrice * item.quantity).toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.price > item.discountPrice)
                                        Text(
                                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textTertiary,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- FINAL SUMMARY PANEL ---
                        OrderSummary(
                          checkout: checkout,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: PlaceOrderButton(
                      text: 'Place Order',
                      onPressed: address == null || delivery == null
                          ? null
                          : () => _placeOrder(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderRow(String title, VoidCallback onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onChange,
          child: const Text(
            'Change',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildWarningCard(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClayCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        borderRadius: 20,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
