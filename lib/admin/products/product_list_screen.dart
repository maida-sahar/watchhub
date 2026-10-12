import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'product_details_screen.dart';
import 'widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProductProvider>().deleteProduct(product.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final displayList = provider.filteredProducts.isNotEmpty || _searchController.text.isNotEmpty
        ? provider.filteredProducts
        : provider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Product Inventory'),
        actions: [
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (opt) => provider.sortProducts(opt),
            itemBuilder: (_) => [
              const PopupMenuItem(value: ProductSortOption.latest, child: Text('Sort by Latest')),
              const PopupMenuItem(value: ProductSortOption.oldest, child: Text('Sort by Oldest')),
              const PopupMenuItem(value: ProductSortOption.priceLowToHigh, child: Text('Price: Low -> High')),
              const PopupMenuItem(value: ProductSortOption.priceHighToLow, child: Text('Price: High -> Low')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, SKU, Brand, Category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => provider.searchProducts(val),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : RefreshIndicator(
                        onRefresh: () => provider.loadProducts(),
                        child: ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final product = displayList[index];
                            return AdminProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                                );
                              },
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                                );
                              },
                              onDelete: () => _confirmDelete(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}