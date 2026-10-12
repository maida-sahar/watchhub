import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/order_model.dart';

class OrderInfoCard extends StatelessWidget {
  final OrderModel order;

  const OrderInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMMM dd, yyyy - hh:mm a').format(order.createdAt);
    final formattedDelivery = DateFormat('EEEE, d MMMM yyyy').format(order.estimatedDeliveryDate);

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Order ID', order.orderId, theme, isSelectable: true),
          const SizedBox(height: 12),
          _buildInfoRow('Order Date', formattedDate, theme),
          const SizedBox(height: 12),
          _buildInfoRow('Order Status', order.orderStatus, theme, isStatus: true),
          const SizedBox(height: 12),
          _buildInfoRow('Payment Method', order.paymentMethod, theme),
          const SizedBox(height: 12),
          _buildInfoRow('Payment Status', order.paymentStatus, theme, isPaymentStatus: true),
          const SizedBox(height: 12),
          _buildInfoRow('Est. Delivery', formattedDelivery, theme),
          if (order.orderStatus.toLowerCase() == 'cancelled') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            _buildInfoRow('Cancelled Date', order.cancelledAt != null ? DateFormat('MMMM dd, yyyy - hh:mm a').format(order.cancelledAt!) : 'N/A', theme),
            const SizedBox(height: 12),
            _buildInfoRow('Cancellation Reason', order.cancellationReason ?? 'No reason provided', theme),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isSelectable = false,
    bool isStatus = false,
    bool isPaymentStatus = false,
  }) {
    Widget valueWidget;

    if (isStatus) {
      valueWidget = _buildStatusChip(value);
    } else if (isPaymentStatus) {
      valueWidget = _buildPaymentStatusChip(value);
    } else if (isSelectable) {
      valueWidget = SelectableText(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      valueWidget = Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: valueWidget,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = AppColors.primaryLight.withOpacity(0.3);
        textColor = AppColors.primary;
        break;
      case 'confirmed':
      case 'processing':
      case 'packed':
      case 'shipped':
      case 'out for delivery':
        chipColor = AppColors.accent.withOpacity(0.12);
        textColor = AppColors.accent;
        break;
      case 'delivered':
        chipColor = AppColors.success.withOpacity(0.12);
        textColor = AppColors.success;
        break;
      case 'cancelled':
        chipColor = AppColors.error.withOpacity(0.12);
        textColor = AppColors.error;
        break;
      default:
        chipColor = AppColors.border;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'paid':
        chipColor = AppColors.success.withOpacity(0.12);
        textColor = AppColors.success;
        break;
      case 'pending':
        chipColor = AppColors.primaryLight.withOpacity(0.3);
        textColor = AppColors.primary;
        break;
      case 'failed':
        chipColor = AppColors.error.withOpacity(0.12);
        textColor = AppColors.error;
        break;
      default:
        chipColor = AppColors.border;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
