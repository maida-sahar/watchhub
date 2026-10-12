import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/models/brand_model.dart';
import 'package:watch_hub/models/product_model.dart';
import 'package:watch_hub/providers/product_provider.dart';
import 'package:watch_hub/screens/brand/widgets/brand_banner.dart';
import 'package:watch_hub/screens/brand/widgets/brand_header.dart';
import 'package:watch_hub/screens/brand/widgets/brand_info.dart';
import 'package:watch_hub/screens/brand/widgets/empty_products_widget.dart';
import 'package:watch_hub/screens/products/widgets/product_grid.dart';
import 'package:watch_hub/screens/products/widgets/product_shimmer.dart';

class BrandDetailsScreen extends StatefulWidget {
  final BrandModel? brand;

  const BrandDetailsScreen({
    super.key,
    this.brand,
  });

  @override
  State<BrandDetailsScreen> createState() => _BrandDetailsScreenState();
}

class _BrandDetailsScreenState extends State<BrandDetailsScreen> {
  BrandModel? _selectedBrand;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final brand = widget.brand ??
          (ModalRoute.of(context)?.settings.arguments as BrandModel?);
      if (brand != null && brand.id.isNotEmpty) {
        _loadProducts(brand.id);
      }
    });
  }

  @override
  void dispose() {
    // Clear filteredProducts slot on exit so it doesn't leak onto other screens
    context.read<ProductProvider>().clearFilters();
    super.dispose();
  }

  Future<void> _loadProducts(String brandId) {
    return context.read<ProductProvider>().loadProductsByBrand(brandId);
  }

  void _navigateToProductDetails(ProductModel product) {
    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    _selectedBrand = widget.brand ??
        (ModalRoute.of(context)?.settings.arguments as BrandModel?);

    final selectedBrand = _selectedBrand;

    // Invalid / Missing Model Handling
    if (selectedBrand == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Brand Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brand Not Found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The requested brand details could not be loaded. Please try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(selectedBrand.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Section
              BrandBanner(bannerUrl: selectedBrand.bannerUrl),

              // Overlapping Header (Logo + Title + Badge)
              BrandHeader(brand: selectedBrand),

              // Brand Info & Statistics
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, _) {
                          final products = productProvider.filteredProducts
                              .where((p) => p.brandId == selectedBrand.id)
                              .toList();
                          return BrandInfo(
                            brand: selectedBrand,
                            totalProducts: products.length,
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Products Section Title with dynamic count
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, _) {
                          final products = productProvider.filteredProducts
                              .where((p) => p.brandId == selectedBrand.id)
                              .toList();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Products',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (products.isNotEmpty)
                                Text(
                                  '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Real Firestore-backed Products Section
                      _buildProductsArea(selectedBrand),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders products for [brand] with loading shimmer, error retry, empty state, and product grid
  Widget _buildProductsArea(BrandModel brand) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.filteredProducts
            .where((p) => p.brandId == brand.id)
            .toList();

        if (productProvider.isLoading && products.isEmpty) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const ProductShimmer(),
          );
        }

        if (productProvider.hasError && products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    productProvider.errorMessage ?? 'Failed to load brand products.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _loadProducts(brand.id),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (products.isEmpty) {
          return const EmptyProductsWidget();
        }

        return ProductGrid(
          products: products,
          onProductTap: _navigateToProductDetails,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        );
      },
    );
  }
}