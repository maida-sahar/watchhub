import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'customer_management_screen.dart';
import 'widgets/customer_activity_card.dart';
import 'widgets/customer_address_card.dart';
import 'widgets/customer_contact_card.dart';
import 'widgets/customer_order_history_card.dart';
import 'widgets/customer_profile_card.dart';
import 'widgets/customer_statistics_card.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final UserModel customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Watch for real-time updates inside the cached provider customers
        final liveCustomer = provider.customers.firstWhere(
          (u) => u.uid == customer.uid,
          orElse: () => customer,
        );

        final totalOrders = provider.getTotalOrders(liveCustomer.uid);
        final completedOrders = provider.getCompletedOrders(liveCustomer.uid);
        final pendingOrders = provider.getPendingOrders(liveCustomer.uid);
        final cancelledOrders = provider.getCancelledOrders(liveCustomer.uid);
        final totalSpending = provider.getTotalSpending(liveCustomer.uid);
        final latestAddress = provider.getLatestShippingAddress(liveCustomer.uid);
        final userOrders = provider.getOrdersForUser(liveCustomer.uid);

        // Sort customer orders descending by date
        final sortedOrders = List.from(userOrders)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final DateTime? lastOrderDate = sortedOrders.isNotEmpty ? sortedOrders.first.createdAt : null;

        final double avgOrderVal = totalOrders > 0 ? (totalSpending / totalOrders) : 0.0;
        final double completionRate = totalOrders > 0 ? completedOrders / totalOrders : 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Customer Details',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerManagementScreen(initialCustomer: liveCustomer),
                    ),
                  );
                },
                tooltip: 'Manage Account Status',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  CustomerProfileCard(customer: liveCustomer),
                  const SizedBox(height: 16),
                  CustomerContactCard(customer: liveCustomer),
                  const SizedBox(height: 16),
                  CustomerAddressCard(address: latestAddress),
                  const SizedBox(height: 16),
                  CustomerStatisticsCard(
                    totalOrders: totalOrders,
                    completedOrders: completedOrders,
                    pendingOrders: pendingOrders,
                    cancelledOrders: cancelledOrders,
                    totalSpending: totalSpending,
                  ),
                  const SizedBox(height: 16),
                  CustomerActivityCard(
                    lastOrderDate: lastOrderDate,
                    averageOrderValue: avgOrderVal,
                    completionRate: completionRate,
                  ),
                  const SizedBox(height: 20),
                  CustomerOrderHistoryCard(
                    orders: userOrders,
                    isLoading: provider.isLoading,
                    errorMessage: provider.errorMessage,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
