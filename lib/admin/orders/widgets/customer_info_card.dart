import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/order_provider.dart';

/// Displays the customer's name, email, and phone for an order.
///
/// Reads `OrderProvider.customerInfo` — the parent screen is
/// responsible for calling `loadCustomerInfo(userId)` once when the
/// Order Details screen opens; this widget only renders whatever state
/// results (loading / loaded / error), it never fetches directly.
class CustomerInfoCard extends StatelessWidget {
  const CustomerInfoCard({
    super.key,
    required this.fallbackUserId,
    this.onViewFullProfile,
  });

  /// Shown if the customer profile can't be loaded, so the admin still
  /// has something to identify the order by.
  final String fallbackUserId;

  /// Called when the admin taps "View Full Profile". When null, the
  /// button is hidden — keeps this widget usable in contexts that
  /// don't want that navigation.
  final VoidCallback? onViewFullProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<OrderProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (provider.isLoadingCustomerInfo)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (provider.customerInfo != null) ...[
              _infoRow(theme, Icons.person_outline, provider.customerInfo!.name),
              _infoRow(theme, Icons.email_outlined, provider.customerInfo!.email),
              if (provider.customerInfo!.phone.isNotEmpty)
                _infoRow(theme, Icons.phone_outlined, provider.customerInfo!.phone),
            ] else
              _infoRow(
                theme,
                Icons.person_outline,
                'Customer ID: $fallbackUserId',
                subtitle: provider.customerInfoError != null
                    ? 'Profile could not be loaded'
                    : null,
              ),
            if (onViewFullProfile != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewFullProfile,
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('View Full Profile'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}