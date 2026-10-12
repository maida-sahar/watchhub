import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/order_model.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderModel order;

  const OrderStatusTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStatus = order.orderStatus.toLowerCase();
    
    // Determine the timeline steps based on whether the order is cancelled
    final List<String> statusSteps = [
      'pending',
      'confirmed',
      'processing',
      'packed',
      'shipped',
      'out for delivery',
      'delivered',
    ];

    final isCancelled = currentStatus == 'cancelled';
    
    // Find index of current status
    int activeIndex = statusSteps.indexOf(currentStatus);
    if (isCancelled) {
      // If cancelled, we insert cancelled after the last updatedAt state or display it at the top/bottom
      // Typically, cancellations happen during pending, confirmed, or processing.
      activeIndex = 3; // Put cancelled as step 4
    }

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (order.orderStatus.toLowerCase() != 'delivered' &&
                  order.orderStatus.toLowerCase() != 'cancelled')
                Text(
                  'Est. Delivery: ${DateFormat('MMM dd').format(order.estimatedDeliveryDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (isCancelled) ...[
            _buildCancelledIndicator(theme),
            const SizedBox(height: 16),
          ],

          // Build vertical timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statusSteps.length,
            itemBuilder: (context, index) {
              final stepStatus = statusSteps[index];
              final stepIndex = index;
              
              bool isCompleted = false;
              bool isActive = false;

              if (!isCancelled) {
                final currentActiveIndex = statusSteps.indexOf(currentStatus);
                isCompleted = stepIndex < currentActiveIndex;
                isActive = stepIndex == currentActiveIndex;
              } else {
                // If cancelled, show steps before cancellation as greyed/completed
                // Cancellation is allowed during pending (0), confirmed (1), processing (2)
                // Let's assume it was cancelled at the current step.
                isCompleted = false; 
                isActive = false;
              }

              final title = _getStatusTitle(stepStatus);
              final description = _getStatusDescription(stepStatus);
              final dateStr = _getStatusDate(stepStatus, isCompleted, isActive);

              return _buildTimelineItem(
                context: context,
                title: title,
                description: description,
                date: dateStr,
                isCompleted: isCompleted,
                isActive: isActive,
                isLast: index == statusSteps.length - 1,
                isCancelledInterrupted: isCancelled,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledIndicator(ThemeData theme) {
    final cancelDate = order.cancelledAt != null 
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(order.cancelledAt!) 
        : DateFormat('MMM dd, yyyy - hh:mm a').format(order.updatedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cancelled on $cancelDate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.cancellationReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${order.cancellationReason}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String description,
    required String date,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    required bool isCancelledInterrupted,
  }) {
    final theme = Theme.of(context);

    Color indicatorColor;
    Widget indicatorChild;

    if (isActive) {
      indicatorColor = AppColors.primary;
      indicatorChild = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else if (isCompleted) {
      indicatorColor = AppColors.primaryLight;
      indicatorChild = const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 14,
      );
    } else {
      indicatorColor = AppColors.border;
      indicatorChild = const SizedBox.shrink();
    }

    // Grey out timeline items if order is cancelled
    if (isCancelledInterrupted) {
      indicatorColor = AppColors.border;
      indicatorChild = const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator line & circle
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: AppColors.primary.withOpacity(0.25), width: 4)
                      : null,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted && !isCancelledInterrupted
                        ? AppColors.primaryLight
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isCancelledInterrupted
                            ? AppColors.textTertiary
                            : (isActive ? AppColors.primary : AppColors.textPrimary),
                      ),
                    ),
                    if (date.isNotEmpty && !isCancelledInterrupted)
                      Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCancelledInterrupted ? AppColors.textTertiary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Processing';
      case 'packed':
        return 'Packed';
      case 'shipped':
        return 'Shipped';
      case 'out for delivery':
        return 'Out For Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'We have received your order request.';
      case 'confirmed':
        return 'Your order has been verified and confirmed.';
      case 'processing':
        return 'Our specialists are preparing your timepiece.';
      case 'packed':
        return 'Your package is sealed and ready for courier pickup.';
      case 'shipped':
        return 'Timepiece in transit with our logistics partner.';
      case 'out for delivery':
        return 'Courier is delivering your package today.';
      case 'delivered':
        return 'Package successfully received. Enjoy your watch!';
      default:
        return '';
    }
  }

  String _getStatusDate(String status, bool isCompleted, bool isActive) {
    // Show createdAt for Pending
    if (status.toLowerCase() == 'pending') {
      return DateFormat('MMM dd, hh:mm a').format(order.createdAt);
    }
    
    // Show updatedAt if this is the active/current status
    if (isActive) {
      return DateFormat('MMM dd, hh:mm a').format(order.updatedAt);
    }

    return '';
  }
}
