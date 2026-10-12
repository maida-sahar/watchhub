import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/providers/checkout_provider.dart';
import 'package:watch_hub/models/checkout_model.dart';
import 'widgets/add_address_button.dart';
import 'widgets/address_form.dart';
import 'widgets/address_list.dart';
import 'widgets/address_shimmer.dart';
import 'widgets/empty_address_widget.dart';

class ShippingAddressScreen extends StatelessWidget {
  const ShippingAddressScreen({super.key});

  void _openAddressForm(BuildContext context, {ShippingAddress? address}) {
    final checkoutProvider = context.read<CheckoutProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressForm(
          initialAddress: address,
          onSubmit: (submittedAddress) async {
            bool success;
            if (address == null) {
              // Creating new address
              final newAddress = submittedAddress.copyWith(
                userId: checkoutProvider.currentUserId ?? '',
              );
              success = await checkoutProvider.addAddress(newAddress);
            } else {
              // Updating address
              success = await checkoutProvider.updateAddress(submittedAddress);
            }

            if (context.mounted) {
              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(address == null ? 'Address saved successfully.' : 'Address updated successfully.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(checkoutProvider.errorMessage ?? 'Failed to save address.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, ShippingAddress address) async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this shipping address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await checkoutProvider.deleteAddress(address.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(checkoutProvider.errorMessage ?? 'Failed to delete address.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSetDefault(BuildContext context, ShippingAddress address) async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final success = await checkoutProvider.setDefaultAddress(address.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkoutProvider.errorMessage ?? 'Failed to set default address.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final addresses = checkoutProvider.addresses;
    final theme = Theme.of(context);

    // Determines if the screen was opened as a selector for checkout or manage mode
    final bool isSelectorMode = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
    final selectedAddressId = checkoutProvider.currentCheckout?.shippingAddress?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Shipping Addresses'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: checkoutProvider.isLoading && addresses.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: AddressShimmer(),
              )
            : addresses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: EmptyAddressWidget(
                        onAddAddress: () => _openAddressForm(context),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => checkoutProvider.loadAddresses(),
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (isSelectorMode) ...[
                          Text(
                            'Select Shipping Address',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        AddressList(
                          addresses: addresses,
                          selectedAddressId: selectedAddressId,
                          showSelectionMode: isSelectorMode,
                          onEdit: (addr) => _openAddressForm(context, address: addr),
                          onDelete: (addr) => _handleDelete(context, addr),
                          onSetDefault: (addr) {
                            if (isSelectorMode) {
                              checkoutProvider.selectShippingAddress(addr);
                              Navigator.of(context).pop();
                            } else {
                              _handleSetDefault(context, addr);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        if (addresses.length < 5)
                          AddAddressButton(
                            onTap: () => _openAddressForm(context),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
