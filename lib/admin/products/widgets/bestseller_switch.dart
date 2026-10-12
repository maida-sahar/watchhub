import 'package:flutter/material.dart';

class BestsellerSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BestsellerSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Best Seller'),
      subtitle: const Text('Mark this item as a top-selling watch'),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}