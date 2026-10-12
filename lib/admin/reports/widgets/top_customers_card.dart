import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class CustomerReportItem {
  final UserModel user;
  final int orderCount;
  final double totalSpent;

  CustomerReportItem({
    required this.user,
    required this.orderCount,
    required this.totalSpent,
  });
}

/// Displays top customers ranked by order count and highest spending.
class TopCustomersCard extends StatelessWidget {
  const TopCustomersCard({
    super.key,
    required this.customerItems,
    required this.currency,
  });

  final List<CustomerReportItem> customerItems;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Rank by order count
    final topByOrders = List<CustomerReportItem>.from(customerItems)
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    final topOrdersSubset = topByOrders.take(5).toList();

    // Rank by spending
    final topBySpending = List<CustomerReportItem>.from(customerItems)
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    final topSpendingSubset = topBySpending.take(5).toList();

    return DefaultTabController(
      length: 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Leaderboards',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Top Orders'),
                  Tab(text: 'Highest Spenders'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _buildCustomerList(context, topOrdersSubset, isOrderCount: true),
                    _buildCustomerList(context, topSpendingSubset, isOrderCount: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    List<CustomerReportItem> items, {
    required bool isOrderCount,
  }) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No customer records found.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final rank = index + 1;

        return Row(
          children: [
            // Rank Badge
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? (rank == 1
                        ? Colors.amber
                        : (rank == 2 ? Colors.grey[400] : Colors.brown[300]))
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundImage: item.user.photoUrl.isNotEmpty ? NetworkImage(item.user.photoUrl) : null,
              child: item.user.photoUrl.isEmpty
                  ? Text(
                      item.user.name.isNotEmpty ? item.user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name & Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.user.name.isNotEmpty ? item.user.name : 'Unknown Customer',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.user.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOrderCount) ...[
                  Text(
                    '${item.orderCount} orders',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${item.totalSpent.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ] else ...[
                  Text(
                    '$currency ${item.totalSpent.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.orderCount} orders',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
