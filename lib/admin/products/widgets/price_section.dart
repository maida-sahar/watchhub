import 'package:flutter/material.dart';

class PriceSection extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController discountPriceController;
  final String selectedCurrency;
  final ValueChanged<String?> onCurrencyChanged;

  const PriceSection({
    super.key,
    required this.priceController,
    required this.discountPriceController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
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
              'Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Regular Price *',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(val);
                      if (price == null || price < 0) {
                        return 'Must be >= 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: discountPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Discount Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final disc = double.tryParse(val);
                        final price = double.tryParse(priceController.text);
                        if (disc == null || disc <= 0) {
                          return 'Must be >= 0';
                        }
                        if (price != null && disc >= price) {
                          return 'Discount < Price';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}