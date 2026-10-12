import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

/// Displays an order's shipping address and delivery method.
class ShippingAddressCard extends StatelessWidget {
  const ShippingAddressCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = order.shippingAddress;
    final delivery = order.deliveryMethod;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    address.addressType,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(address.phone, style: theme.textTheme.bodyMedium),
            if (address.alternatePhone != null && address.alternatePhone!.isNotEmpty)
              Text('Alt: ${address.alternatePhone}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '${address.streetAddress}, ${address.area}, ${address.city}, '
              '${address.province}, ${address.country} - ${address.postalCode}',
              style: theme.textTheme.bodyMedium,
            ),
            if (address.landmark != null && address.landmark!.isNotEmpty)
              Text('Landmark: ${address.landmark}', style: theme.textTheme.bodySmall),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${delivery.title} • Est. ${delivery.estimatedDeliveryDays} day(s)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}