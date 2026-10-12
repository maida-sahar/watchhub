import 'package:flutter/material.dart';

class ColorFilter extends StatelessWidget {
  final List<String> availableColors;
  final String? selectedColor;
  final ValueChanged<String?> onSelected;

  const ColorFilter({
    super.key,
    required this.availableColors,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableColors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Color',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableColors.map((color) {
            final isSelected = selectedColor == color;
            return ChoiceChip(
              selected: isSelected,
              label: Text(color),
              onSelected: (selected) {
                onSelected(selected ? color : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}