import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'widgets/customer_action_button.dart';
import 'widgets/customer_action_dialog.dart';
import 'widgets/customer_status_badge.dart';

class CustomerManagementScreen extends StatelessWidget {
  final UserModel initialCustomer;

  const CustomerManagementScreen({
    super.key,
    required this.initialCustomer,
  });

  Future<void> _handleActiveToggle(BuildContext context, UserProvider provider, UserModel customer) async {
    final newActiveState = !customer.isActive;
    final action = newActiveState ? 'Activate' : 'Deactivate';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => CustomerActionDialog(
        title: '$action Account',
        content: newActiveState
            ? 'Are you sure you want to activate this account? The customer will regain full login access.'
            : 'Are you sure you want to deactivate this account? The customer will be signed out and unable to log in, but their data will remain in the database.',
        confirmLabel: action,
        confirmColor: newActiveState ? AppColors.success : Colors.amber[800] ?? Colors.amber,
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final success = await provider.updateCustomerActive(customer.uid, newActiveState);
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account has been successfully ${newActiveState ? "activated" : "deactivated"}.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.statusUpdateError ?? 'Failed to update account status.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        provider.clearStatusUpdateError();
      }
    }
  }

  Future<void> _handleBlockToggle(BuildContext context, UserProvider provider, UserModel customer) async {
    final newBlockState = !customer.isBlocked;
    final action = newBlockState ? 'Block' : 'Unblock';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => CustomerActionDialog(
        title: '$action Customer',
        content: newBlockState
            ? 'Are you sure you want to block this customer? They will be signed out immediately and restricted from logging in, checkout, wishlists, and carts.'
            : 'Are you sure you want to unblock this customer? They will regain regular customer access.',
        confirmLabel: action,
        confirmColor: newBlockState ? AppColors.error : AppColors.success,
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final success = await provider.updateCustomerBlocked(customer.uid, newBlockState);
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer has been successfully ${newBlockState ? "blocked" : "unblocked"}.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.statusUpdateError ?? 'Failed to update customer status.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        provider.clearStatusUpdateError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage Account',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, _) {
            // Watch for real-time updates inside the cached provider customers
            final customer = provider.customers.firstWhere(
              (u) => u.uid == initialCustomer.uid,
              orElse: () => initialCustomer,
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Detail Summary Card
                  ClayCard(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                            backgroundImage: customer.photoUrl.isNotEmpty
                                ? NetworkImage(customer.photoUrl)
                                : null,
                            child: customer.photoUrl.isEmpty
                                ? Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase()
                                        : '?',
                                    style: AppTypography.headlineSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name.isNotEmpty ? customer.name : 'No Name',
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  customer.email,
                                  style: AppTypography.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Panel Card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Account Status Label',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            CustomerStatusBadge(
                              isActive: customer.isActive,
                              isBlocked: customer.isBlocked,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                          child: Text(
                            'Administrative Controls',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // 1. Block/Unblock Actions
                        if (customer.isBlocked)
                          CustomerActionButton(
                            label: 'Unblock Customer Account',
                            icon: Icons.lock_open_rounded,
                            color: AppColors.success,
                            isLoading: provider.isUpdatingStatus,
                            onPressed: () => _handleBlockToggle(context, provider, customer),
                          )
                        else
                          CustomerActionButton(
                            label: 'Block Customer Account',
                            icon: Icons.lock_outline_rounded,
                            color: AppColors.error,
                            isLoading: provider.isUpdatingStatus,
                            onPressed: () => _handleBlockToggle(context, provider, customer),
                          ),
                        
                        // 2. Activate/Deactivate Actions
                        if (customer.isBlocked)
                          CustomerActionButton(
                            label: 'Activate Customer Account',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            isLoading: false,
                            onPressed: null, // Disabled: unblock first
                          )
                        else if (!customer.isActive)
                          CustomerActionButton(
                            label: 'Activate Customer Account',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            isLoading: provider.isUpdatingStatus,
                            onPressed: () => _handleActiveToggle(context, provider, customer),
                          )
                        else
                          CustomerActionButton(
                            label: 'Deactivate Customer Account',
                            icon: Icons.pause_circle_outline_rounded,
                            color: Colors.amber[800] ?? Colors.amber,
                            isLoading: provider.isUpdatingStatus,
                            onPressed: () => _handleActiveToggle(context, provider, customer),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
