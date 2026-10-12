import 'package:flutter/material.dart';

class TagsSection extends StatelessWidget {
  final List<String> tags;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final Function(String tag) onRemoveTag;

  const TagsSection({
    super.key,
    required this.tags,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags & Keywords',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: const InputDecoration(
                      hintText: 'Enter tag (e.g. Luxury, Chronograph)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => onAddTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAddTag,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () => onRemoveTag(tag),
                  deleteIconColor: Colors.red.shade400,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}