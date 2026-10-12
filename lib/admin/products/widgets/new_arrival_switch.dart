import 'package:flutter/material.dart';

class NewArrivalSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NewArrivalSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('New Arrival'),
      subtitle: const Text('Display in new arrivals section'),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}