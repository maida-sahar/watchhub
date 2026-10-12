import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/category_banner.dart';
import '../../widgets/category_header.dart';
import '../../widgets/category_info.dart';
import '../products/widgets/empty_product_widget.dart';
import '../products/widgets/product_grid.dart';
import '../products/widgets/product_shimmer.dart';

/// Category Details screen, reached by tapping a category on
/// `CategoryScreen` (the Category Listing screen).
///
/// Accepts the selected category two ways:
/// • [category] — passed directly (the normal path, since the listing
///   screen already has the full `CategoryModel` in memory and can hand
///   it straight to `Navigator`, avoiding any extra fetch).
/// • [categoryId] — used as a fallback (e.g. a deep link that only has
///   an id). In that case this screen calls
///   `CategoryProvider.loadCategoryById()` and reads the result from
///   `CategoryProvider.selectedCategory`, showing a loading indicator
///   while that call is in flight.
///
/// This screen never imports Firebase, `CategoryService`, or
/// `CategoryRepository` — it only ever reads [category] directly or
/// goes through `CategoryProvider`.
class CategoryDetailsScreen extends StatefulWidget {
  const CategoryDetailsScreen({
    super.key,
    this.category,
    this.categoryId,
  }) : assert(
          category != null || categoryId != null,
          'Either category or categoryId must be provided.',
        );

  /// The category to display, if already available (typical case).
  final CategoryModel? category;

  /// A category id to look up via `CategoryProvider`, used only when
  /// [category] is not provided directly.
  final String? categoryId;

  /// Convenience constructor that reads the `CategoryModel` passed via
  /// `Navigator.pushNamed(..., arguments: category)`, for routes wired
  /// up through the app's named-route table.
  static Widget fromRouteArguments(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CategoryModel) {
      return CategoryDetailsScreen(category: args);
    }
    if (args is String) {
      return CategoryDetailsScreen(categoryId: args);
    }
    // No usable arguments were passed — render the screen with neither
    // field set is disallowed by the constructor's assert, so instead
    // surface this as an explicit error screen the user can back out of.
    return const _InvalidCategoryScreen();
  }

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.category == null && widget.categoryId != null) {
        context.read<CategoryProvider>().loadCategoryById(widget.categoryId!);
      }
      final resolvedId = widget.category?.id ?? widget.categoryId;
      if (resolvedId != null && resolvedId.isNotEmpty) {
        _loadProducts(resolvedId);
      }
    });
  }

  @override
  void dispose() {
    // ProductProvider.filteredProducts is a single shared "browsable
    // result" slot also used by the Product catalogue/search screen.
    // Clearing it here on the way out keeps that screen from silently
    // showing this category's products after the user leaves this page.
    context.read<ProductProvider>().clearFilters();
    super.dispose();
  }

  Future<void> _loadProducts(String categoryId) {
    return context.read<ProductProvider>().loadProductsByCategory(categoryId);
  }

  Future<void> _retryLoadById() async {
    final id = widget.categoryId;
    if (id == null) return;
    await context.read<CategoryProvider>().loadCategoryById(id);
  }

  @override
  Widget build(BuildContext context) {
    // Direct-category path: nothing to load, render immediately.
    if (widget.category != null) {
      return _buildScaffold(widget.category!);
    }

    // categoryId path: resolve through CategoryProvider only.
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final resolved = provider.selectedCategory;
        final isMatchingCategory =
            resolved != null && resolved.id == widget.categoryId;

        if (provider.isLoading && !isMatchingCategory) {
          return _buildLoadingScaffold();
        }

        if (isMatchingCategory) {
          return _buildScaffold(resolved);
        }

        // Either an error occurred, or the lookup completed with no
        // matching category — both are treated as an invalid category.
        return _buildErrorScaffold(
          provider.errorMessage ?? 'This category could not be found.',
        );
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(String message) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  if (widget.categoryId != null)
                    FilledButton.icon(
                      onPressed: _retryLoadById,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetails(ProductModel product) {
    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
  }

  Widget _buildScaffold(CategoryModel category) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadProducts(category.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryBanner(category: category),
                  CategoryHeader(category: category),
                  CategoryInfo(category: category),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<ProductProvider>(
                          builder: (context, productProvider, _) {
                            final products = productProvider.filteredProducts
                                .where((p) => p.categoryId == category.id)
                                .toList();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Products',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                if (products.isNotEmpty)
                                  Text(
                                    '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildProductsArea(category),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: _BackButton(onTap: () => Navigator.of(context).maybePop()),
          ),
        ],
      ),
    );
  }

  /// Real Firestore-backed products for [category] — loading, error, and
  /// empty states all handled explicitly, and no dummy/placeholder
  /// products are ever shown.
  Widget _buildProductsArea(CategoryModel category) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.filteredProducts
            .where((p) => p.categoryId == category.id)
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
                  Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(
                    productProvider.errorMessage ?? 'Failed to load products.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _loadProducts(category.id),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (products.isEmpty) {
          return EmptyProductWidget(onReset: () => _loadProducts(category.id));
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

/// A circular, semi-transparent back button meant to sit on top of the
/// banner image, readable regardless of the image behind it.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Fallback error screen used by [CategoryDetailsScreen.fromRouteArguments]
/// when the navigation arguments are missing or of an unexpected type.
class _InvalidCategoryScreen extends StatelessWidget {
  const _InvalidCategoryScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              const Text(
                'Invalid category. Please go back and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}