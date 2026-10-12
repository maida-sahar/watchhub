// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_spacing.dart';

import '../../config/app_routes.dart';
import '../../models/brand_model.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../brand/widgets/brand_card.dart';
import '../categories/category_details_screen.dart';
import '../products/widgets/product_card.dart';
import '../products/widgets/product_shimmer.dart';

// ---------- Main Home Screen ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedNavIndex = 0; // for bottom nav

  String? _selectedCategoryId;

  // Bottom navigation items
  List<BottomNavigationBarItem> _buildNavItems(BuildContext context) {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
      BottomNavigationBarItem(
        icon: Selector<WishlistProvider, int>(
          selector: (_, wishlistProvider) => wishlistProvider.wishlistCount,
          builder: (context, wishlistCount, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite_border_rounded),
                if (wishlistCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Text(
                        wishlistCount > 99 ? '99+' : '$wishlistCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        label: 'Wishlist',
      ),
      BottomNavigationBarItem(
        icon: Selector<CartProvider, int>(
          selector: (_, cartProvider) => cartProvider.cartCount,
          builder: (context, cartCount, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        label: 'Cart',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
    ];
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeData();
    });
  }

  /// Loads everything the Home Page needs from backend services / providers.
  Future<void> _loadHomeData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUid;

    final categoryProvider = context.read<CategoryProvider>();
    final productProvider = context.read<ProductProvider>();
    final brandProvider = context.read<BrandProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (uid != null && uid.isNotEmpty) {
      notificationProvider.watchNotifications(uid);
    }

    await Future.wait([
      categoryProvider.loadActiveCategories().catchError((_) {}),
      productProvider.loadActiveProducts().catchError((_) {}),
      productProvider.loadFeaturedProducts().catchError((_) {}),
      productProvider.loadNewArrivalProducts().catchError((_) {}),
      productProvider.loadBestSellerProducts().catchError((_) {}),
      brandProvider.loadActiveBrands().catchError((_) {}),
      brandProvider.loadFeaturedBrands().catchError((_) {}),
    ]);
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.search);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.customerWishlist);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.customerCart);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.customerProfile);
        break;
    }
  }

  void _openCategory(CategoryModel category) {
    setState(() => _selectedCategoryId = category.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryDetailsScreen(category: category)),
    );
  }

  void _openProduct(ProductModel product) {
    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
  }

  void _openCatalogue() {
    Navigator.pushNamed(context, AppRoutes.customerProducts);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUid;
    final role = auth.currentRole ?? 'customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, uid, role),
      body: SafeArea(
        child: Consumer4<CategoryProvider, ProductProvider, BrandProvider, NotificationProvider>(
          builder: (context, categoryProvider, productProvider, brandProvider, notificationProvider, _) {
            return RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Chips (Filter Bar at Top)
                    _buildCategoryChips(categoryProvider),
                    const SizedBox(height: AppSpacing.lg),

                    // Categories Visual Section
                    _buildCategoriesVisualSection(categoryProvider),

                    // Brands & Brand Logos Section
                    _buildBrandsSection(brandProvider),

                    if (productProvider.hasError) _buildErrorBanner(productProvider.errorMessage),

                    ..._buildProductContent(categoryProvider, productProvider),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String? uid, String role) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'WatchHub',
        style: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unreadCount = (uid != null && uid.isNotEmpty)
                ? notifProvider.getUnreadCount(uid, role)
                : 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryChips(CategoryProvider categoryProvider) {
    final categories = List<CategoryModel>.from(categoryProvider.activeCategories)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    if (categoryProvider.isLoading && categories.isEmpty) {
      return const SizedBox(height: 48);
    }
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return _CategoryChip(
              label: 'All',
              isSelected: isSelected,
              onTap: () => setState(() => _selectedCategoryId = null),
            );
          }
          final category = categories[index - 1];
          final isSelected = _selectedCategoryId == category.id;
          return _CategoryChip(
            label: category.name,
            isSelected: isSelected,
            onTap: () => _openCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesVisualSection(CategoryProvider categoryProvider) {
    final categories = List<CategoryModel>.from(categoryProvider.activeCategories)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // Still loading and nothing to show yet — keep the section reserved with
    // a shimmer-style placeholder rather than collapsing it to nothing, so
    // the layout doesn't jump once data arrives.
    if (categoryProvider.isLoading && categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Categories', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // The load actually failed (e.g. a Firestore query error) — surface it
    // instead of silently vanishing, so it's obvious something needs fixing
    // rather than looking like the app has no categories at all.
    if (categoryProvider.hasError && categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Categories', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            _buildErrorBanner(categoryProvider.errorMessage ?? 'Could not load categories.'),
          ],
        ),
      );
    }

    // Genuinely no categories exist yet — say so instead of hiding the
    // section, so the gap is explained rather than looking accidental.
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Categories', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Text(
                'No categories available',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Categories',
            seeAll: () => Navigator.pushNamed(context, AppRoutes.customerCategories),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 90,
                    child: GestureDetector(
                      onTap: () => _openCategory(category),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: category.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: category.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.watch_outlined,
                                        size: 32,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.watch_outlined,
                                      size: 32,
                                      color: AppColors.textSecondary,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsSection(BrandProvider brandProvider) {
    final brands = List<BrandModel>.from(
      brandProvider.activeBrands.isNotEmpty
          ? brandProvider.activeBrands
          : brandProvider.brands.where((b) => b.isActive).toList(),
    )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    if (brandProvider.isLoading && brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Top Brands', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 164,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Same as Categories: a failed Brand load (most commonly a missing
    // Firestore composite index on isActive/isFeatured + displayOrder)
    // must not look identical to "there are simply no brands yet".
    if (brandProvider.hasError && brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Top Brands', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            _buildErrorBanner(brandProvider.errorMessage ?? 'Could not load brands.'),
          ],
        ),
      );
    }

    if (brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Top Brands', seeAll: null),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Text(
                'No brands available',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Top Brands',
            seeAll: () => Navigator.pushNamed(context, AppRoutes.customerBrands),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 164,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 140,
                    child: UserBrandCard(
                      brand: brand,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.brandDetails,
                        arguments: brand,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductContent(
    CategoryProvider categoryProvider,
    ProductProvider productProvider,
  ) {
    final isInitialLoad = productProvider.isLoading && productProvider.activeProducts.isEmpty;
    if (isInitialLoad) {
      return [_buildLoadingSections()];
    }

    final categories = List<CategoryModel>.from(categoryProvider.activeCategories)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final activeProducts = productProvider.activeProducts;

    final sections = <Widget>[];

    if (productProvider.featuredProducts.isNotEmpty) {
      sections.add(_buildProductSection(
        title: 'Featured Products',
        products: productProvider.featuredProducts,
        onSeeAll: _openCatalogue,
      ));
    }

    for (final category in categories) {
      final productsInCategory = activeProducts.where((p) => p.categoryId == category.id).toList();
      if (productsInCategory.isEmpty) continue;
      sections.add(_buildProductSection(
        title: category.name,
        products: productsInCategory,
        onSeeAll: () => _openCategory(category),
      ));
    }

    if (productProvider.newArrivalProducts.isNotEmpty) {
      sections.add(_buildProductSection(
        title: 'New Arrivals',
        products: productProvider.newArrivalProducts,
        onSeeAll: _openCatalogue,
      ));
    }

    if (productProvider.bestSellerProducts.isNotEmpty) {
      sections.add(_buildProductSection(
        title: 'Best Sellers',
        products: productProvider.bestSellerProducts,
        onSeeAll: _openCatalogue,
      ));
    }

    if (sections.isEmpty && !productProvider.hasError) {
      sections.add(_buildEmptyState());
    }

    return sections;
  }

  Widget _buildLoadingSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Loading Watches', seeAll: null),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: SizedBox(width: 160, child: ProductShimmer()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              'No Products Available Yet',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'New watches added by our team will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Something went wrong while loading products.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
            TextButton(
              onPressed: _loadHomeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required List<ProductModel> products,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, seeAll: onSeeAll),
          const SizedBox(height: AppSpacing.md),
          _ProductHorizontalList(products: products, onProductTap: _openProduct),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: _buildNavItems(context),
        ),
      ),
    );
  }
}

// ---------- Sub-Widgets ----------

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? seeAll;

  const _SectionHeader({required this.title, required this.seeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          if (seeAll != null)
            GestureDetector(
              onTap: seeAll,
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductHorizontalList extends StatelessWidget {
  final List<ProductModel> products;
  final ValueChanged<ProductModel> onProductTap;

  const _ProductHorizontalList({required this.products, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SizedBox(
              width: 160,
              child: UserProductCard(
                product: product,
                onTap: () => onProductTap(product),
              ),
            ),
          );
        },
      ),
    );
  }
}