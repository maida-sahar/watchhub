import 'package:flutter/material.dart';

class ProductSpecifications extends StatelessWidget {
  final Map<String, dynamic>? specifications;

  const ProductSpecifications({
    super.key,
    this.specifications,
  });

  @override
  Widget build(BuildContext context) {
    if (specifications == null || specifications!.isEmpty) {
      return const SizedBox.shrink();
    }

    final specsList = specifications!.entries.toList();

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: List.generate(specsList.length, (index) {
              final entry = specsList[index];
              final isEven = index % 2 == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.transparent,
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(11))
                      : index == specsList.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(11))
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}