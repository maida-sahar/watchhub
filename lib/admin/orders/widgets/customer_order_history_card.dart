import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../order_details_screen.dart';
import 'order_card.dart' show OrderStatusDisplay;

/// Displays a customer's order history: Order ID, date, status, and
/// grand total for each order, tappable to open that order's full
/// Admin Order Details screen.
class CustomerOrderHistoryCard extends StatelessWidget {
  const CustomerOrderHistoryCard({
    super.key,
    required this.orders,
    required this.isLoading,
    this.errorMessage,
  });

  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;

  void _openOrder(BuildContext context, OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailsScreen(orderId: order.orderId, initialOrder: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedOrders = List<OrderModel>.from(orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order History (${orders.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (errorMessage != null)
              Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              )
            else if (sortedOrders.isEmpty)
              Text(
                'No previous orders.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              ...sortedOrders.map((order) {
                final statusColor = OrderStatusDisplay.color(context, order.orderStatus);
                return InkWell(
                  onTap: () => _openOrder(context, order),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order.orderId}',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(order.createdAt),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                OrderStatusDisplay.label(order.orderStatus),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.currency} ${order.grandTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
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