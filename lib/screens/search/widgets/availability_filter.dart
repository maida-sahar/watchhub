import 'package:flutter/material.dart';

class AvailabilityFilter extends StatelessWidget {
  final String? selectedAvailability; // 'in_stock', 'low_stock', 'out_of_stock'
  final ValueChanged<String?> onSelected;

  const AvailabilityFilter({
    super.key,
    required this.selectedAvailability,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': 'In Stock', 'value': 'in_stock'},
      {'label': 'Low Stock', 'value': 'low_stock'},
      {'label': 'Out of Stock', 'value': 'out_of_stock'},
    ];

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = selectedAvailability == opt['value'];
            return ChoiceChip(
              selected: isSelected,
              label: Text(opt['label']!),
              onSelected: (selected) {
                onSelected(selected ? opt['value'] : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}