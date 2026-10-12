import 'package:flutter/material.dart';

import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/utils/price_parser.dart';

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
        side: const BorderSide(color: AppColors.border),
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
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      // Use the shared sanitizing parser (not
                      // double.tryParse directly) so a value like
                      // "$ 12,500" — currency symbol and/or thousands
                      // separator — is still recognized as the valid
                      // number 12500, instead of failing to parse and
                      // incorrectly showing "Must be >= 0".
                      final price = PriceParser.tryParse(val);
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
                      if (val != null && val.trim().isNotEmpty) {
                        final disc = PriceParser.tryParse(val);
                        final price = PriceParser.tryParse(priceController.text);
                        if (disc == null || disc < 0) {
                          return 'Must be >= 0';
                        }
                        // Spec: discount must NOT be greater than the
                        // regular price — a discount equal to the
                        // regular price is valid (no discount applied),
                        // so this is a strict '>' check, not '>='.
                        if (price != null && disc > price) {
                          return 'Must not exceed Regular Price';
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