import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';

/// Displays a customer's name, profile image, and account creation
/// date. Purely presentational — the parent screen is responsible for
/// streaming [profile] via `OrderProvider.watchCustomerProfile()`.
class CustomerProfileCard extends StatelessWidget {
  const CustomerProfileCard({
    super.key,
    required this.profile,
    required this.isLoading,
    this.errorMessage,
    this.fallbackUserId,
  });

  final UserModel? profile;
  final bool isLoading;
  final String? errorMessage;

  /// Shown if the profile can't be loaded, so the admin still has
  /// something to identify the customer by.
  final String? fallbackUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : profile == null
                ? Text(
                    errorMessage ?? 'Customer ID: ${fallbackUserId ?? 'unknown'}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: ClipOval(
                          child: profile!.photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: profile!.photoUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person_outline,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile!.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer since ${_formatDate(profile!.createdAt)}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }
}