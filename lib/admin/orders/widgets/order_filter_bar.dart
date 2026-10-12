import 'package:flutter/material.dart';

/// The set of status filters an admin can apply to the orders list.
/// 'all' shows every order regardless of status.
enum OrderStatusFilter {
  all,
  pending,
  confirmed,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusFilterX on OrderStatusFilter {
  /// The label shown on the filter chip.
  String get label {
    switch (this) {
      case OrderStatusFilter.all:
        return 'All';
      case OrderStatusFilter.pending:
        return 'Pending';
      case OrderStatusFilter.confirmed:
        return 'Confirmed';
      case OrderStatusFilter.processing:
        return 'Processing';
      case OrderStatusFilter.packed:
        return 'Packed';
      case OrderStatusFilter.shipped:
        return 'Shipped';
      case OrderStatusFilter.outForDelivery:
        return 'Out For Delivery';
      case OrderStatusFilter.delivered:
        return 'Delivered';
      case OrderStatusFilter.cancelled:
        return 'Cancelled';
    }
  }

  /// The lowercase `orderStatus` value this filter matches against
  /// (matching how `OrderModel.orderStatus` is actually stored).
  /// `null` for [OrderStatusFilter.all], since it matches everything.
  String? get statusValue {
    switch (this) {
      case OrderStatusFilter.all:
        return null;
      case OrderStatusFilter.pending:
        return 'pending';
      case OrderStatusFilter.confirmed:
        return 'confirmed';
      case OrderStatusFilter.processing:
        return 'processing';
      case OrderStatusFilter.packed:
        return 'packed';
      case OrderStatusFilter.shipped:
        return 'shipped';
      case OrderStatusFilter.outForDelivery:
        return 'out for delivery';
      case OrderStatusFilter.delivered:
        return 'delivered';
      case OrderStatusFilter.cancelled:
        return 'cancelled';
    }
  }
}

/// Horizontal scrollable row of status filter chips for the Admin
/// Orders list.
class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OrderStatusFilter selected;
  final ValueChanged<OrderStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: OrderStatusFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}