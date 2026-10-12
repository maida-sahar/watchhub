// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/providers/checkout_provider.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  void _changeAddress(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.customerShippingAddress,
      arguments: true, // Enable selector mode
    );
  }

  void _handleProceed(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.customerDeliveryMethod);
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final currentCheckout = checkoutProvider.currentCheckout;
    final theme = Theme.of(context);

    if (currentCheckout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout Overview')),
        body: const Center(
          child: Text('No active checkout session. Please return to the Cart screen.'),
        ),
      );
    }

    final address = currentCheckout.shippingAddress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Overview'),
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
                        // --- SHIPPING ADDRESS SECTION ---
                        _buildSectionTitle(context, 'Shipping Address'),
                        const SizedBox(height: 10),
                        if (address == null)
                          ClayCard(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            borderRadius: 20,
                            child: Column(
                              children: [
                                const Text(
                                  'No shipping address selected.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _changeAddress(context),
                                  icon: const Icon(Icons.add_location_rounded),
                                  label: const Text('Add / Select Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ClayCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    TextButton(
                                      onPressed: () => _changeAddress(context),
                                      child: const Text(
                                        'Change',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
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

                        // --- CART ITEMS SECTION ---
                        _buildSectionTitle(context, 'Items in Order'),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentCheckout.cartItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = currentCheckout.cartItems[index];
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
                      ],
                    ),
                  ),

                  // --- PRICE INVOICE SUMMARY PANEL ---
                  ClayCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    borderRadius: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPriceRow(context, 'Subtotal', currentCheckout.subtotal),
                        if (currentCheckout.discount > 0)
                          _buildPriceRow(context, 'Product Discounts', -currentCheckout.discount, isDiscount: true),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Sum',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${currentCheckout.grandTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ClayButton(
                            onPressed: address == null ? null : () => _handleProceed(context),
                            child: Text(
                              'Proceed to Delivery Method',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double value, {bool isDiscount = false}) {
    final theme = Theme.of(context);
    final valueText = isDiscount
        ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';
    final valueColor = isDiscount ? AppColors.success : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valueText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
