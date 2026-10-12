import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilter;
  final VoidCallback onOpenSort;
  final int activeFilterCount;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilter,
    required this.onOpenSort,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search watches, brands, SKU...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                            onPressed: onClear,
                          )
                        : const SizedBox.shrink();
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Sort Button
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.swap_vert, size: 22, color: AppColors.textPrimary),
            onPressed: onOpenSort,
            tooltip: 'Sort Options',
          ),
        ),
        const SizedBox(width: 8),

        // Filter Button with Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: activeFilterCount > 0
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeFilterCount > 0 ? AppColors.primary : AppColors.border,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20,
                  color: activeFilterCount > 0 ? AppColors.onPrimary : AppColors.textPrimary,
                ),
                onPressed: onOpenFilter,
                tooltip: 'Filter Options',
              ),
            ),
            if (activeFilterCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}