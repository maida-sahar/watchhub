import 'package:flutter/material.dart';

import '../../../models/checkout_model.dart';

/// Displays a customer's shipping address.
///
/// [address] is sourced from a specific order's `shippingAddress` (the
/// selected order, or the customer's most recent order if none was
/// given directly) — `UserModel` itself has no saved-address fields, so
/// an order's shipping address is the only place this data lives.
class CustomerAddressCard extends StatelessWidget {
  const CustomerAddressCard({super.key, required this.address});

  final ShippingAddress? address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            if (address == null)
              Text(
                'No address on file yet.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address!.streetAddress,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _detailRow(theme, 'Area', address!.area),
              _detailRow(theme, 'City', address!.city),
              _detailRow(theme, 'Province/State', address!.province),
              _detailRow(theme, 'Postal Code', address!.postalCode),
              _detailRow(theme, 'Country', address!.country),
              if (address!.landmark != null && address!.landmark!.isNotEmpty)
                _detailRow(theme, 'Landmark', address!.landmark!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}