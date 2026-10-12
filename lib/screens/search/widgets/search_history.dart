import 'package:flutter/material.dart';
import 'recent_search_chip.dart';

class SearchHistory extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onSelectSearch;
  final ValueChanged<String> onDeleteSearch;
  final VoidCallback onClearAll;

  const SearchHistory({
    super.key,
    required this.history,
    required this.onSelectSearch,
    required this.onDeleteSearch,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: history.map((term) {
            return RecentSearchChip(
              label: term,
              onTap: () => onSelectSearch(term),
              onDelete: () => onDeleteSearch(term),
            );
          }).toList(),
        ),
      ],
    );
  }
}