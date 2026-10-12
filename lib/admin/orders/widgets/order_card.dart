import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

/// Shared status → (label, color) formatting, reused by [OrderCard],
/// `OrderStatusDropdown`, and `OrderTimeline` so status presentation
/// stays consistent across the Admin Orders module without duplicating
/// the same switch statement in three separate files.
class OrderStatusDisplay {
  OrderStatusDisplay._();

  /// Converts a stored lowercase status (e.g. 'out for delivery') into
  /// a display label (e.g. 'Out For Delivery').
  static String label(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Returns a color representing the status, for badges/chips.
  static Color color(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.indigo;
      case 'packed':
        return Colors.teal;
      case 'shipped':
        return Colors.deepPurple;
      case 'out for delivery':
        return Colors.cyan.shade700;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

/// A Material 3 card summarizing a single [OrderModel] in the Admin
/// Orders list.
///
/// Purely presentational — tapping it is reported via [onTap]; this
/// widget never touches `OrderProvider` or Firebase directly.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = OrderStatusDisplay.color(context, order.orderStatus);
    final statusLabel = OrderStatusDisplay.label(order.orderStatus);
    final itemCount = order.items.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.orderId}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'} • ${order.currency} ${order.grandTotal.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Placed ${_formatDate(order.createdAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
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