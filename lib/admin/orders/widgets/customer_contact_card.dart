import 'package:flutter/material.dart';

import '../../../models/user_model.dart';

/// Displays a customer's email address and phone number.
class CustomerContactCard extends StatelessWidget {
  const CustomerContactCard({super.key, required this.profile});

  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (profile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _row(theme, Icons.email_outlined, profile!.email),
            if (profile!.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _row(theme, Icons.phone_outlined, profile!.phone),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}