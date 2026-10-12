import 'package:flutter/material.dart';

class ProductDescription extends StatefulWidget {
  final String shortDescription;
  final String description;

  const ProductDescription({
    super.key,
    required this.shortDescription,
    required this.description,
  });

  @override
  State<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasShortDesc = widget.shortDescription.isNotEmpty;
    final hasFullDesc = widget.description.isNotEmpty;

    if (!hasShortDesc && !hasFullDesc) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        if (hasShortDesc && !_isExpanded)
          Text(
            widget.shortDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        if (hasFullDesc && (_isExpanded || !hasShortDesc)) ...[
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
        if (hasFullDesc && widget.description.length > 120)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _isExpanded ? 'Show Less' : 'Read More',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}