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
    final safeMin = minPrice >= 0 ? minPrice : 0.0;
    final safeMax = maxPrice > safeMin ? maxPrice : safeMin + 1000.0;
    final clampedStart = currentRange.start.clamp(safeMin, safeMax);
    final clampedEnd = currentRange.end.clamp(clampedStart, safeMax);
    final safeRange = RangeValues(clampedStart, clampedEnd);
    final divisionCount = ((safeMax - safeMin) / 10).clamp(1, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price Range',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${safeRange.start.toStringAsFixed(0)} - \$${safeRange.end.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: safeRange,
          min: safeMin,
          max: safeMax,
          divisions: divisionCount,
          labels: RangeLabels(
            '\$${safeRange.start.toStringAsFixed(0)}',
            '\$${safeRange.end.toStringAsFixed(0)}',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}