import 'package:flutter/material.dart';

class FeaturedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FeaturedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Featured Product'),
      subtitle: const Text('Display in featured banners and home hero section'),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}