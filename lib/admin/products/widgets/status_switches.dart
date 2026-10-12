import 'package:flutter/material.dart';
import 'featured_switch.dart';
import 'bestseller_switch.dart';
import 'new_arrival_switch.dart';

class StatusSwitches extends StatelessWidget {
  final bool isActive;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isNewArrival;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onBestSellerChanged;
  final ValueChanged<bool> onNewArrivalChanged;

  const StatusSwitches({
    super.key,
    required this.isActive,
    required this.isFeatured,
    required this.isBestSeller,
    required this.isNewArrival,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    required this.onBestSellerChanged,
    required this.onNewArrivalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: const Text('Visible to customers in storefront'),
              value: isActive,
              onChanged: onActiveChanged,
              activeColor: Colors.green,
            ),
            const Divider(height: 1),
            FeaturedSwitch(
              value: isFeatured,
              onChanged: onFeaturedChanged,
            ),
            const Divider(height: 1),
            BestsellerSwitch(
              value: isBestSeller,
              onChanged: onBestSellerChanged,
            ),
            const Divider(height: 1),
            NewArrivalSwitch(
              value: isNewArrival,
              onChanged: onNewArrivalChanged,
            ),
          ],
        ),
      ),
    );
  }
}