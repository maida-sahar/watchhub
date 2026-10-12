import 'package:flutter/material.dart';

/// A widget to select and modify quantity of cart items.
///
/// Supports increment (+), decrement (-), and direct quantity input on tap.
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int stock;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final ValueChanged<int>? onQuantityChanged;
  final bool isProcessing;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.stock,
    this.onIncrement,
    this.onDecrement,
    this.onQuantityChanged,
    this.isProcessing = false,
  });

  void _showDirectInputDialog(BuildContext context) {
    if (isProcessing) return;

    final controller = TextEditingController(text: quantity.toString());
    final theme = Theme.of(context);

    showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter quantity (Max stock: $stock):',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Quantity',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = int.tryParse(controller.text);
                if (input != null && input >= 0) {
                  Navigator.of(ctx).pop(input);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    ).then((newValue) {
      if (newValue != null && newValue != quantity && onQuantityChanged != null) {
        if (newValue > stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot exceed available stock of $stock units.'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        onQuantityChanged!(newValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = quantity > 1 && !isProcessing;
    final canIncrement = quantity < stock && !isProcessing;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            iconSize: 14,
            icon: Icon(
              Icons.remove,
              color: canDecrement
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onPressed: canDecrement ? onDecrement : null,
          ),
          // Current Quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 20,
              child: Center(
                child: isProcessing
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Tooltip(
                        message: 'Tap to input directly',
                        child: InkWell(
                          onTap: () => _showDirectInputDialog(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                            child: Text(
                              '$quantity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // Increment button
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            iconSize: 14,
            icon: Icon(
              Icons.add,
              color: canIncrement
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onPressed: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}