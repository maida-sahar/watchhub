import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'edit_product_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.watch, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),
            if (product.galleryImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.galleryImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: product.galleryImages[index],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined, size: 24),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('${product.brandName} | ${product.categoryName}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 12),
            Text('\$${product.discountPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(product.description.isEmpty ? 'No detailed description provided.' : product.description),
            const SizedBox(height: 20),
            const Text('Inventory Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListTile(
              title: const Text('SKU'),
              subtitle: Text(product.sku),
            ),
            ListTile(
              title: const Text('Stock Units Available'),
              subtitle: Text('${product.stock}'),
            ),
            ListTile(
              title: const Text('Total Sold Units'),
              subtitle: Text('${product.soldCount}'),
            ),
          ],
        ),
      ),
    );
  }
}