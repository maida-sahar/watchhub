import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/checkout_model.dart';

class CustomerAddressCard extends StatelessWidget {
  final ShippingAddress? address;

  const CustomerAddressCard({
    super.key,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Shipping Address',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (address == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'No shipping address registered yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else ...[
            _addressRow('Recipient', address!.fullName),
            const Divider(height: 20, color: AppColors.divider),
            _addressRow('Street Address', address!.streetAddress),
            const Divider(height: 20, color: AppColors.divider),
            _addressRow('City', address!.city),
            const Divider(height: 20, color: AppColors.divider),
            _addressRow('Province / State', address!.province),
            const Divider(height: 20, color: AppColors.divider),
            _addressRow('Country', address!.country),
            const Divider(height: 20, color: AppColors.divider),
            _addressRow('Postal Code', address!.postalCode),
            if (address!.phone.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider),
              _addressRow('Contact Phone', address!.phone),
            ],
          ],
        ],
      ),
    );
  }

  Widget _addressRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
