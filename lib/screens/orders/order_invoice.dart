import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/clay_widgets.dart';
import '../../models/order_model.dart';

/// A read-only invoice view for a placed order.
///
/// This is not a PDF export — it renders the existing [OrderModel] fields
/// (already saved to Firestore at order-placement time) into an invoice-style
/// layout the customer can view and screenshot/share. No new provider,
/// repository, or service is introduced; this screen only formats data that
/// [OrderModel] already carries.
class OrderInvoiceScreen extends StatelessWidget {
  final OrderModel order;

  const OrderInvoiceScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.iconPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClayCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WatchHub',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          order.orderStatus.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _row('Order ID', '#${order.orderId}'),
                  _row('Order Date', dateFormat.format(order.createdAt)),
                  _row('Payment Method', order.paymentMethod),
                  _row('Payment Status', order.paymentStatus[0].toUpperCase() + order.paymentStatus.substring(1)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Billed To ---
            ClayCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billed To',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(order.shippingAddress.fullName,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${order.shippingAddress.streetAddress}, ${order.shippingAddress.area}\n'
                    '${order.shippingAddress.city}, ${order.shippingAddress.province}, ${order.shippingAddress.country} - ${order.shippingAddress.postalCode}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(order.shippingAddress.phone,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Line Items ---
            ClayCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productName,
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '×${item.quantity}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '\$${(item.discountPrice * item.quantity).toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Pricing Breakdown ---
            ClayCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _priceRow('Subtotal', order.subtotal),
                  if (order.discount > 0) _priceRow('Discount', -order.discount, color: AppColors.success),
                  if (order.couponDiscount > 0) _priceRow('Coupon Discount', -order.couponDiscount, color: AppColors.success),
                  _priceRow(
                    'Delivery (${order.deliveryMethod.title})',
                    order.shippingCharge,
                    isFree: order.shippingCharge == 0,
                  ),
                  if (order.tax > 0) _priceRow('Tax', order.tax),
                  const Divider(height: 24),
                  _priceRow('Total', order.grandTotal, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false, bool isFree = false, Color? color}) {
    final text = isFree ? 'FREE' : '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: color ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}