import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/brand_provider.dart';

class BrandDropdown extends StatelessWidget {
  final String? selectedBrandId;
  final ValueChanged<String?> onChanged;

  const BrandDropdown({
    super.key,
    required this.selectedBrandId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandProvider>(
      builder: (context, brandProvider, child) {
        final brands = brandProvider.brands;

        return DropdownButtonFormField<String>(
          value: selectedBrandId,
          decoration: const InputDecoration(
            labelText: 'Brand *',
            prefixIcon: Icon(Icons.watch_outlined),
            border: OutlineInputBorder(),
          ),
          items: brands.map((brand) {
            return DropdownMenuItem<String>(
              value: brand.id,
              child: Text(brand.name),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (val) =>
              val == null || val.isEmpty ? 'Please select a brand' : null,
        );
      },
    );
  }
}