import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';

class RatingFilter extends StatelessWidget {
  final double? selectedRating;
  final ValueChanged<double?> onSelected;

  const RatingFilter({
    super.key,
    required this.selectedRating,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ratings = [4.0, 3.0, 2.0, 1.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minimum Rating',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ratings.map((rating) {
            final isSelected = selectedRating == rating;
            return ChoiceChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${rating.toInt()}'),
                  const Icon(Icons.star, size: 14, color: AppColors.primary),
                  const Text(' & up'),
                ],
              ),
              onSelected: (selected) {
                onSelected(selected ? rating : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}