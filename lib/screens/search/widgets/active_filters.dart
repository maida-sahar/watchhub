import 'package:flutter/material.dart';
import 'filter_bottom_sheet.dart';

class ActiveFilters extends StatelessWidget {
  final FilterStateData filters;
  final VoidCallback onClearAll;
  final ValueChanged<String> onRemoveFilter;

  const ActiveFilters({
    super.key,
    required this.filters,
    required this.onClearAll,
    required this.onRemoveFilter,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> activeChips = [];

    if (filters.category != null) {
      activeChips.add({'type': 'category', 'label': 'Category: ${filters.category}'});
    }
    for (var brand in filters.selectedBrands) {
      activeChips.add({'type': 'brand:$brand', 'label': 'Brand: $brand'});
    }
    if (filters.minRating != null) {
      activeChips.add({'type': 'rating', 'label': '${filters.minRating!.toInt()}★ & up'});
    }
    if (filters.availability != null) {
      activeChips.add({'type': 'availability', 'label': filters.availability!.replaceAll('_', ' ').toUpperCase()});
    }
    if (filters.color != null) {
      activeChips.add({'type': 'color', 'label': 'Color: ${filters.color}'});
    }
    if (filters.discountedOnly) {
      activeChips.add({'type': 'discounted', 'label': 'Discounted'});
    }
    if (filters.isFeatured) {
      activeChips.add({'type': 'featured', 'label': 'Featured'});
    }
    if (filters.isBestSeller) {
      activeChips.add({'type': 'bestseller', 'label': 'Best Seller'});
    }
    if (filters.isNewArrival) {
      activeChips.add({'type': 'newarrival', 'label': 'New Arrival'});
    }

    if (activeChips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              InkWell(
                onTap: onClearAll,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              ...activeChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Chip(
                    label: Text(chip['label']!, style: const TextStyle(fontSize: 11)),
                    onDeleted: () => onRemoveFilter(chip['type']!),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}