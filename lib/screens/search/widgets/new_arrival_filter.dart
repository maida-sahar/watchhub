import 'package:flutter/material.dart';

class NewArrivalFilter extends StatelessWidget {
  final bool isNewArrival;
  final ValueChanged<bool> onChanged;

  const NewArrivalFilter({
    super.key,
    required this.isNewArrival,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('New Arrivals Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: isNewArrival,
      onChanged: onChanged,
    );
  }
}
