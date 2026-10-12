import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

/// Displays aggregate statistics computed from a customer's order
/// history: total orders, completed/cancelled/pending counts, and
/// total spending. All values are derived client-side from the already
/// real-time-streamed [orders] list — no separate query is made purely
/// for these numbers.
class CustomerStatisticsCard extends StatelessWidget {
  const CustomerStatisticsCard({super.key, required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalOrders = orders.length;
    final completedOrders =
        orders.where((o) => o.orderStatus.trim().toLowerCase() == 'delivered').length;
    final cancelledOrders =
        orders.where((o) => o.orderStatus.trim().toLowerCase() == 'cancelled').length;
    final pendingOrders = totalOrders - completedOrders - cancelledOrders;

    // Spending only counts orders that weren't cancelled — a cancelled
    // order was never actually fulfilled/paid out, so including it
    // would overstate how much the customer has genuinely spent.
    final totalSpending = orders
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled')
        .fold<double>(0, (sum, o) => sum + o.grandTotal);
    final currency = orders.isNotEmpty ? orders.first.currency : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Statistics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statTile(theme, 'Total Orders', '$totalOrders', Icons.receipt_long_outlined),
                _statTile(theme, 'Completed', '$completedOrders', Icons.check_circle_outline,
                    color: Colors.green),
                _statTile(theme, 'Cancelled', '$cancelledOrders', Icons.cancel_outlined,
                    color: theme.colorScheme.error),
                _statTile(theme, 'Pending', '$pendingOrders', Icons.hourglass_empty,
                    color: Colors.orange),
                _statTile(
                  theme,
                  'Total Spending',
                  '$currency ${totalSpending.toStringAsFixed(2)}',
                  Icons.payments_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(ThemeData theme, String label, String value, IconData icon, {Color? color}) {
    final tileColor = color ?? theme.colorScheme.primary;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tileColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}