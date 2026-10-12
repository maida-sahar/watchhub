import 'package:flutter/material.dart';

class BestSellerFilter extends StatelessWidget {
  final bool isBestSeller;
  final ValueChanged<bool> onChanged;

  const BestSellerFilter({
    super.key,
    required this.isBestSeller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Best Sellers Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: isBestSeller,
      onChanged: onChanged,
    );
  }
}