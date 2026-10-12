import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import 'report_statistics_card.dart';

class CustomerOverviewCard extends StatelessWidget {
  final List<UserModel> customers;
  final List<OrderModel> orders;

  const CustomerOverviewCard({
    super.key,
    required this.customers,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate metrics
    final totalCustomersCount = customers.length;
    
    // Calculate new customers (joined last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newCustomersCount = customers.where((u) => u.createdAt.isAfter(thirtyDaysAgo)).length;

    // Calculate returning customers ratio
    final customerIdsWithOrders = orders.map((o) => o.userId).toSet();
    final returningCustomersCount = customerIdsWithOrders.where((id) {
      final customerOrders = orders.where((o) => o.userId == id).toList();
      return customerOrders.length > 1;
    }).length;
    final totalActiveCustomers = customerIdsWithOrders.length;
    final returningRatio = totalActiveCustomers == 0 ? 0.0 : (returningCustomersCount / totalActiveCustomers) * 100;

    // Average spending per customer
    final totalRevenue = orders
        .where((o) => o.orderStatus.toLowerCase() != 'cancelled')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);
    final avgSpending = totalCustomersCount == 0 ? 0.0 : totalRevenue / totalCustomersCount;

    final stats = [
      ReportStatEntry(
        label: 'Total Customers',
        value: totalCustomersCount.toString(),
        icon: Icons.people_rounded,
        color: Colors.purple,
      ),
      ReportStatEntry(
        label: 'New (Last 30 Days)',
        value: newCustomersCount.toString(),
        icon: Icons.person_add_rounded,
        color: Colors.indigo,
      ),
      ReportStatEntry(
        label: 'Returning Rate',
        value: '${returningRatio.toStringAsFixed(1)}%',
        icon: Icons.replay_rounded,
        color: Colors.pink,
      ),
      ReportStatEntry(
        label: 'Avg Spend / Cust',
        value: '\$${avgSpending.toStringAsFixed(0)}',
        icon: Icons.shopping_bag_rounded,
        color: Colors.green,
      ),
    ];

    // Compute top customers list
    final Map<String, double> spendingMap = {};
    for (final order in orders) {
      if (order.orderStatus.toLowerCase() == 'cancelled') continue;
      spendingMap[order.userId] = (spendingMap[order.userId] ?? 0) + order.grandTotal;
    }

    final topCustomerEntries = spendingMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportStatisticsCard(
          title: 'Customer Analytics',
          entries: stats,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Spenders',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (topCustomerEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        'No customer transactions in system.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topCustomerEntries.take(3).length,
                    itemBuilder: (context, index) {
                      final entry = topCustomerEntries[index];
                      // Find customer name from customers list
                      final customerObj = customers.firstWhere(
                        (c) => c.uid == entry.key,
                        orElse: () => UserModel(
                          uid: entry.key,
                          name: 'Customer ID: ${entry.key.length > 5 ? entry.key.substring(0, 5) : entry.key}',
                          email: '',
                          phone: '',
                          photoUrl: '',
                          role: UserRole.customer,
                          isActive: true,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerObj.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    customerObj.email.isNotEmpty
                                        ? customerObj.email
                                        : 'Guest Account',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
