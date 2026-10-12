import 'package:flutter/material.dart';

class SpecificationsSection extends StatelessWidget {
  final Map<String, String> specifications;
  final VoidCallback onAddSpec;
  final Function(String key) onRemoveSpec;

  const SpecificationsSection({
    super.key,
    required this.specifications,
    required this.onAddSpec,
    required this.onRemoveSpec,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Specifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: onAddSpec,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Spec'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (specifications.isEmpty)
              const Text(
                'No specifications added yet (e.g. Case Size: 42mm, Movement: Automatic).',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: specifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = specifications.entries.elementAt(index);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => onRemoveSpec(entry.key),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}