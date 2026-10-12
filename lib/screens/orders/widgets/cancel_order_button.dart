import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import 'cancel_order_dialog.dart';
import 'cancellation_reason_sheet.dart';

class CancelOrderButton extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onSuccess;

  const CancelOrderButton({super.key, required this.order, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus.toLowerCase();
    
    // Cancellation is allowed ONLY for pending, confirmed, or processing
    final isCancellable = status == 'pending' || status == 'confirmed' || status == 'processing';

    if (!isCancellable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: OutlinedButton(
            onPressed: orderProvider.isLoading
                ? null
                : () => _handleCancellation(context, orderProvider),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: const BorderSide(color: AppColors.error, width: 1.5),
              backgroundColor: AppColors.error.withOpacity(0.02),
            ),
            child: orderProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.error,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Cancel Order',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleCancellation(BuildContext context, OrderProvider orderProvider) async {
    // 1. Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CancelOrderDialog(),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    // 2. Show cancellation reason bottom sheet
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CancellationReasonSheet(),
    );

    if (reason == null) return;

    if (!context.mounted) return;

    // 3. Trigger cancellation call
    final bool success = await orderProvider.cancelOrder(order.orderId, reason);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (onSuccess != null) {
        onSuccess!();
      }
    } else {
      final errorMsg = orderProvider.errorMessage ?? 'Failed to cancel order.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
