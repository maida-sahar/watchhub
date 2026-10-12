import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/providers/product_provider.dart';
import 'package:watch_hub/models/product_model.dart';
import 'widgets/product_grid.dart';
import 'widgets/featured_products.dart';
import 'widgets/best_seller_products.dart';
import 'widgets/new_arrival_products.dart';
import 'widgets/product_shimmer.dart';
import 'widgets/empty_product_widget.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final p = context.read<ProductProvider>();
    await Future.wait([
      p.loadActiveProducts(),
      p.loadFeaturedProducts(),
      p.loadBestSellerProducts(),
      p.loadNewArrivalProducts(),
    ]);
  }

  void _navigateToDetails(ProductModel product) {
    // Navigates to user details screen (Product Details User module intentionally excluded per requirements)
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final activeList = provider.filteredProducts.isNotEmpty || _searchController.text.isNotEmpty
        ? provider.filteredProducts
        : provider.activeProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WatchHub Catalogue'),
        elevation: 0,
      ),
      body: provider.hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage ?? 'An error occurred'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search watches, brands, or tags...',
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
                  ),
                  if (_searchController.text.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: FeaturedProductsSection(
                        products: provider.featuredProducts,
                        onProductTap: _navigateToDetails,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: BestSellerProductsSection(
                        products: provider.bestSellerProducts,
                        onProductTap: _navigateToDetails,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: NewArrivalProductsSection(
                        products: provider.newArrivalProducts,
                        onProductTap: _navigateToDetails,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('All Watches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  provider.isLoading
                      ? SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, __) => const ProductShimmer(),
                              childCount: 6,
                            ),
                          ),
                        )
                      : activeList.isEmpty
                          ? SliverFillRemaining(
                              child: EmptyProductWidget(
                                onReset: () {
                                  _searchController.clear();
                                  provider.clearFilters();
                                },
                              ),
                            )
                          : SliverFillRemaining(
                              child: ProductGrid(
                                products: activeList,
                                onProductTap: _navigateToDetails,
                              ),
                            ),
                ],
              ),
            ),
    );
  }
}