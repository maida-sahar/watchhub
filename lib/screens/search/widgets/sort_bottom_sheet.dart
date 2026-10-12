import 'package:flutter/material.dart';

enum SortOption {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
  mostPopular,
  alphabeticalAZ,
  alphabeticalZA,
  bestSeller,
  featured,
  newArrival,
  highestDiscount,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newest:
        return 'Newest Arrivals';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.highestRated:
        return 'Highest Rated';
      case SortOption.mostPopular:
        return 'Most Popular';
      case SortOption.alphabeticalAZ:
        return 'Alphabetical (A - Z)';
      case SortOption.alphabeticalZA:
        return 'Alphabetical (Z - A)';
      case SortOption.bestSeller:
        return 'Best Sellers First';
      case SortOption.featured:
        return 'Featured First';
      case SortOption.newArrival:
        return 'Newest Tagged First';
      case SortOption.highestDiscount:
        return 'Highest Discount';
    }
  }
}

class SortBottomSheet extends StatelessWidget {
  final SortOption selectedSort;
  final ValueChanged<SortOption> onSelectSort;

  const SortBottomSheet({
    super.key,
    required this.selectedSort,
    required this.onSelectSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sort Products By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: SortOption.values.map((option) {
                final isSelected = selectedSort == option;
                return ListTile(
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    onSelectSort(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}