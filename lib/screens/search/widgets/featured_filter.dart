import 'package:flutter/material.dart';

class FeaturedFilter extends StatelessWidget {
  final bool isFeatured;
  final ValueChanged<bool> onChanged;

  const FeaturedFilter({
    super.key,
    required this.isFeatured,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Featured Products Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: isFeatured,
      onChanged: onChanged,
    );
  }
}