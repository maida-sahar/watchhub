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
      title: const Text('Featured Brand'),
      subtitle: const Text('Highlight this brand on the main store page'),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}