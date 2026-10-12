import 'package:flutter/material.dart';

class PriceRangeSlider extends StatelessWidget {
  final RangeValues currentRange;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues> onChanged;

  const PriceRangeSlider({
    super.key,
    required this.currentRange,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price Range',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${currentRange.start.toStringAsFixed(0)} - \$${currentRange.end.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: currentRange,
          min: minPrice,
          max: maxPrice,
          divisions: ((maxPrice - minPrice) / 10).clamp(1, 100).toInt(),
          labels: RangeLabels(
            '\$${currentRange.start.toStringAsFixed(0)}',
            '\$${currentRange.end.toStringAsFixed(0)}',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}