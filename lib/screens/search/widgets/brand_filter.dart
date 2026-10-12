import 'package:flutter/material.dart';

class BrandFilter extends StatelessWidget {
  final List<String> brands;
  final List<String> selectedBrands;
  final ValueChanged<String> onToggleBrand;

  const BrandFilter({
    super.key,
    required this.brands,
    required this.selectedBrands,
    required this.onToggleBrand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Brands',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brands.map((brand) {
            final isSelected = selectedBrands.contains(brand);
            return FilterChip(
              selected: isSelected,
              label: Text(brand),
              onSelected: (_) => onToggleBrand(brand),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}