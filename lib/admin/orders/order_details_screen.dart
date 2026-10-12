import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'customer_order_details_screen.dart';
import 'widgets/customer_info_card.dart';
import 'widgets/order_status_dropdown.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/order_timeline.dart';
import 'widgets/ordered_products_list.dart';
import 'widgets/payment_info_card.dart';
import 'widgets/shipping_address_card.dart';

/// Admin Order Details screen: shows everything about a single order
/// and lets an admin update its status.
///
/// Named `AdminOrderDetailsScreen` to avoid ambiguity with the existing
/// customer-facing `OrderDetailsScreen` in `screens/orders/`.
///
/// Reuses `OrderProvider.watchOrderById()` — the same real-time stream
/// the customer-facing screen uses — so a status change made here shows
/// up immediately both here and on the customer's own order tracking
/// screen, with no extra plumbing needed for "the user app should
/// automatically receive updated status."
class AdminOrderDetailsScreen extends StatefulWidget {
  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  final String orderId;

  /// Optional order already available from the list screen, shown
  /// immediately while the live stream subscription spins up, so the
  /// screen never has to show a blank loading state for data the admin
  /// already had a moment ago.
  final OrderModel? initialOrder;

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  bool _hasLoadedCustomerInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.watchOrderById(widget.orderId);
      provider.watchOrderStatusHistory(widget.orderId);

      // If we already have the order from the list screen, load the
      // customer profile immediately rather than waiting a stream tick.
      if (widget.initialOrder != null) {
        provider.loadCustomerInfo(widget.initialOrder!.userId);
        _hasLoadedCustomerInfo = true;
      }
    });
  }

  @override
  void dispose() {
    // context.read is safe here: the element is still mounted during
    // dispose(), it's only unmounted afterward.
    context.read<OrderProvider>().clearCurrentOrder();
    context.read<OrderProvider>().clearStatusHistory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final liveOrder = (provider.currentOrder != null &&
                    provider.currentOrder!.orderId == widget.orderId)
                ? provider.currentOrder
                : null;
            final order = liveOrder ?? widget.initialOrder;

            if (order == null) {
              if (provider.errorMessage != null) {
                return _buildErrorState(provider.errorMessage!);
              }
              return const Center(child: CircularProgressIndicator());
            }

            // Lazily trigger the customer lookup once the live order
            // arrives, in case initialOrder wasn't provided (e.g. a
            // future deep-link entry point).
            if (!_hasLoadedCustomerInfo) {
              _hasLoadedCustomerInfo = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<OrderProvider>().loadCustomerInfo(order.userId);
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.orderId}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: OrderStatusDropdown(
                        orderId: order.orderId,
                        currentStatus: order.orderStatus,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomerInfoCard(
                    fallbackUserId: order.userId,
                    onViewFullProfile: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerOrderDetailsScreen(
                            userId: order.userId,
                            contextOrder: order,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ShippingAddressCard(order: order),
                  const SizedBox(height: 16),
                  OrderedProductsList(order: order),
                  const SizedBox(height: 16),
                  PaymentInfoCard(order: order),
                  const SizedBox(height: 16),
                  OrderSummaryCard(order: order),
                  const SizedBox(height: 16),
                  const OrderTimeline(),
                  const SizedBox(height: 24),
                  if (order.cancellationReason != null && order.cancellationReason!.isNotEmpty)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Cancellation reason: ${order.cancellationReason}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<OrderProvider>().watchOrderById(widget.orderId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}