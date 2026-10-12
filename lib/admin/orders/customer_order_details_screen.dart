import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checkout_model.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'widgets/customer_address_card.dart';
import 'widgets/customer_contact_card.dart';
import 'widgets/customer_order_history_card.dart';
import 'widgets/customer_profile_card.dart';
import 'widgets/customer_statistics_card.dart';
import 'widgets/order_card.dart' show OrderStatusDisplay;

/// Admin screen showing a customer's complete profile in the context
/// of one of their orders: profile, contact info, shipping address,
/// order information (for the selected order), statistics across all
/// their orders, and full order history.
///
/// Reached from `AdminOrderDetailsScreen`'s customer info card, or
/// from `CustomerOrderHistoryCard` when navigating between a
/// customer's past orders.
///
/// This screen talks ONLY to `OrderProvider` — it never imports or
/// calls Firebase, `OrderService`, or `OrderRepository` directly.
class CustomerOrderDetailsScreen extends StatefulWidget {
  const CustomerOrderDetailsScreen({
    super.key,
    required this.userId,
    this.contextOrder,
  });

  /// The customer whose profile/history this screen shows.
  final String userId;

  /// The specific order this screen was opened from, if any — its
  /// `orderStatus`, `paymentStatus`, `deliveryMethod`, and
  /// `shippingAddress` populate the "Order Information" and address
  /// sections. If null (e.g. a future direct entry point), those
  /// sections fall back to the customer's most recent order once their
  /// order history has loaded.
  final OrderModel? contextOrder;

  @override
  State<CustomerOrderDetailsScreen> createState() => _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState extends State<CustomerOrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.watchCustomerProfile(widget.userId);
      provider.watchCustomerOrderHistory(widget.userId);
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().clearCustomerProfile();
    context.read<OrderProvider>().clearCustomerOrderHistory();
    super.dispose();
  }

  /// The order whose status/payment/delivery/address should be shown
  /// in the "Order Information" section: the order this screen was
  /// opened from, or — failing that — the customer's most recent order.
  OrderModel? _resolveDisplayOrder(List<OrderModel> history) {
    if (widget.contextOrder != null) return widget.contextOrder;
    if (history.isEmpty) return null;
    final sorted = List<OrderModel>.from(history)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final displayOrder = _resolveDisplayOrder(provider.customerOrderHistory);
            final ShippingAddress? address = displayOrder?.shippingAddress;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerProfileCard(
                    profile: provider.customerProfile,
                    isLoading: provider.isLoadingCustomerProfile,
                    errorMessage: provider.customerProfileError,
                    fallbackUserId: widget.userId,
                  ),
                  const SizedBox(height: 16),
                  CustomerContactCard(profile: provider.customerProfile),
                  const SizedBox(height: 16),
                  CustomerAddressCard(address: address),
                  const SizedBox(height: 16),
                  if (displayOrder != null) _buildOrderInfoCard(context, displayOrder),
                  if (displayOrder != null) const SizedBox(height: 16),
                  CustomerStatisticsCard(orders: provider.customerOrderHistory),
                  const SizedBox(height: 16),
                  CustomerOrderHistoryCard(
                    orders: provider.customerOrderHistory,
                    isLoading: provider.isLoadingCustomerOrderHistory,
                    errorMessage: provider.customerOrderHistoryError,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// "Order Information" section: total orders, total spent, last
  /// order date, plus the selected order's current status, payment
  /// status, and delivery method. Rendered inline here rather than as
  /// a separate widget file, since this task's file list didn't
  /// include one for it and it's a thin composition of data already
  /// available on [OrderModel] and the already-loaded order history.
  Widget _buildOrderInfoCard(BuildContext context, OrderModel displayOrder) {
    final theme = Theme.of(context);
    final history = context.watch<OrderProvider>().customerOrderHistory;

    final totalOrders = history.length;
    final totalSpent = history
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled')
        .fold<double>(0, (sum, o) => sum + o.grandTotal);
    final lastOrderDate = history.isEmpty
        ? displayOrder.createdAt
        : history.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _infoRow(theme, 'Total Orders', '$totalOrders'),
            _infoRow(theme, 'Total Amount Spent',
                '${displayOrder.currency} ${totalSpent.toStringAsFixed(2)}'),
            _infoRow(theme, 'Last Order Date', _formatDate(lastOrderDate)),
            _infoRow(theme, 'Current Order Status',
                OrderStatusDisplay.label(displayOrder.orderStatus)),
            _infoRow(theme, 'Payment Status', displayOrder.paymentStatus.toUpperCase()),
            _infoRow(theme, 'Delivery Method', displayOrder.deliveryMethod.title),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }
}