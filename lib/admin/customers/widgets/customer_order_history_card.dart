import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../models/order_model.dart';
import 'customer_order_card.dart';

class CustomerOrderHistoryCard extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;

  const CustomerOrderHistoryCard({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          errorMessage!,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sort orders newest first for history view
    final sortedOrders = List<OrderModel>.from(orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Order History (${sortedOrders.length})',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (sortedOrders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No orders placed yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              return CustomerOrderCard(order: sortedOrders[index]);
            },
          ),
      ],
    );
  }
}
