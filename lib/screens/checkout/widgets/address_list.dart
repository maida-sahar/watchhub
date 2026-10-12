import 'package:flutter/material.dart';
import 'package:watch_hub/models/checkout_model.dart';
import 'shipping_address_card.dart';

class AddressList extends StatelessWidget {
  final List<ShippingAddress> addresses;
  final Function(ShippingAddress) onEdit;
  final Function(ShippingAddress) onDelete;
  final Function(ShippingAddress) onSetDefault;
  final String? selectedAddressId;
  final bool showSelectionMode;

  const AddressList({
    super.key,
    required this.addresses,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    this.selectedAddressId,
    this.showSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final address = addresses[index];
        final isSelected = selectedAddressId == address.id;

        return ShippingAddressCard(
          address: address,
          isSelected: isSelected,
          showSelectionMode: showSelectionMode,
          onEdit: () => onEdit(address),
          onDelete: () => onDelete(address),
          onSetDefault: () => onSetDefault(address),
        );
      },
    );
  }
}
