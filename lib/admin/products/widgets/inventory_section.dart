import 'package:flutter/material.dart';

class InventorySection extends StatelessWidget {
  final TextEditingController skuController;
  final TextEditingController stockController;
  final TextEditingController minStockController;

  const InventorySection({
    super.key,
    required this.skuController,
    required this.stockController,
    required this.minStockController,
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
              'Inventory',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: skuController,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'SKU is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      final stock = int.tryParse(val);
                      if (stock == null || stock < 0) {
                        return 'Must be >= 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Warning',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final minStock = int.tryParse(val);
                        if (minStock == null || minStock < 0) {
                          return 'Must be >= 0';
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