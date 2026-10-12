import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/clay_widgets.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'widgets/order_info_card.dart';
import 'widgets/ordered_product_card.dart';
import 'widgets/order_status_timeline.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/cancel_order_button.dart';
import 'order_invoice.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? order;
  final String? orderId;

  const OrderDetailsScreen({
    super.key,
    this.order,
    this.orderId,
  }) : assert(order != null || orderId != null, 'Either order or orderId must be provided.');

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String get _resolvedOrderId => widget.orderId ?? widget.order?.orderId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().watchOrderById(_resolvedOrderId);
    });
  }

  @override
  void dispose() {
    // Clear subscription so subsequent detail pages don't inherit old state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderProvider>().clearCurrentOrder();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProviderWatch = context.watch<OrderProvider>();
    final resolvedOrder = (orderProviderWatch.currentOrder != null &&
            orderProviderWatch.currentOrder!.orderId == _resolvedOrderId)
        ? orderProviderWatch.currentOrder
        : (widget.order?.orderId == _resolvedOrderId ? widget.order : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.iconPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: resolvedOrder == null
            ? null
            : [
                IconButton(
                  tooltip: 'View Invoice',
                  icon: const Icon(Icons.receipt_long_outlined, color: AppColors.iconPrimary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderInvoiceScreen(order: resolvedOrder),
                      ),
                    );
                  },
                ),
              ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // Use stream order if available, else fall back to initial order argument (if IDs match)
          final order = (orderProvider.currentOrder != null &&
                  orderProvider.currentOrder!.orderId == _resolvedOrderId)
              ? orderProvider.currentOrder
              : (widget.order?.orderId == _resolvedOrderId ? widget.order : null);

          // Handle Error state
          if (orderProvider.errorMessage != null && order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      orderProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        orderProvider.watchOrderById(_resolvedOrderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle Loading state (only if we don't have static arguments as fallback)
          if (order == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Order General Info Card
                OrderInfoCard(order: order),
                const SizedBox(height: 20),

                // 2. Real-time Tracking Timeline
                OrderStatusTimeline(order: order),
                const SizedBox(height: 20),

                // 3. Shipping Address Card
                _buildShippingAddressCard(order, theme),
                const SizedBox(height: 20),

                // 4. Delivery Method Card
                _buildDeliveryMethodCard(order, theme),
                const SizedBox(height: 20),

                // 5. Ordered Products List
                Text(
                  'Ordered Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) => OrderedProductCard(item: item)),
                const SizedBox(height: 8),

                // 6. Pricing Summary Card
                OrderSummaryCard(order: order),
                const SizedBox(height: 8),

                // 7. Cancel Order Button (visible only in pending/confirmed/processing)
                CancelOrderButton(
                  order: order,
                  onSuccess: () {
                    // Re-query order state to show cancelled status instantly
                    orderProvider.watchOrderById(_resolvedOrderId);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShippingAddressCard(OrderModel order, ThemeData theme) {
    final address = order.shippingAddress;
    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  address.addressType.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            address.fullName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address.phone + (address.alternatePhone != null ? ' / ${address.alternatePhone}' : ''),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${address.streetAddress}, ${address.area}\n${address.city}, ${address.province}\n${address.country} - ${address.postalCode}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (address.landmark != null && address.landmark!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Landmark: ${address.landmark}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodCard(OrderModel order, ThemeData theme) {
    final method = order.deliveryMethod;
    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Method',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                method.deliveryCharge == 0 ? 'FREE' : '\$${method.deliveryCharge.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}