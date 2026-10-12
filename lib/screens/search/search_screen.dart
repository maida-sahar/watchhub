import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../products/product_details_screen.dart'; // Correct User Details Screen import
import 'widgets/active_filters.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/no_results_widget.dart';
import 'widgets/search_bar.dart';
import 'widgets/search_history.dart';
import 'widgets/search_result_grid.dart';
import 'widgets/search_shimmer.dart';
import 'widgets/sort_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Search History State (max 10)
  final List<String> _recentSearches = [];

  // Active Sorting & Filters State
  SortOption _selectedSort = SortOption.newest;
  late FilterStateData _filters;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filters = FilterStateData(
      priceRange: const RangeValues(0, 500000),
      selectedBrands: [],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (productProvider.activeProducts.isEmpty && productProvider.products.isEmpty) {
        productProvider.loadActiveProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = query.trim();
      });
      if (_searchQuery.isNotEmpty && !_recentSearches.contains(_searchQuery)) {
        setState(() {
          _recentSearches.insert(0, _searchQuery);
          if (_recentSearches.length > 10) _recentSearches.removeLast();
        });
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterStateData(
        priceRange: const RangeValues(0, 500000),
        selectedBrands: [],
      );
    });
  }

  void _navigateToProductDetails(
    BuildContext context,
    ProductModel product,
    String currentUserId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  void _removeSingleFilter(String type) {
    setState(() {
      if (type == 'category') _filters.category = null;
      if (type.startsWith('brand:')) {
        final brandName = type.substring(6);
        _filters.selectedBrands.remove(brandName);
      }
      if (type == 'rating') _filters.minRating = null;
      if (type == 'availability') _filters.availability = null;
      if (type == 'color') _filters.color = null;
      if (type == 'discounted') _filters.discountedOnly = false;
      if (type == 'featured') _filters.isFeatured = false;
      if (type == 'bestseller') _filters.isBestSeller = false;
      if (type == 'newarrival') _filters.isNewArrival = false;
    });
  }

  int _countActiveFilters() {
    int count = 0;
    if (_filters.category != null) count++;
    count += _filters.selectedBrands.length;
    if (_filters.minRating != null) count++;
    if (_filters.availability != null) count++;
    if (_filters.color != null) count++;
    if (_filters.discountedOnly) count++;
    if (_filters.isFeatured) count++;
    if (_filters.isBestSeller) count++;
    if (_filters.isNewArrival) count++;
    return count;
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> allProducts) {
    return allProducts.where((p) {
      // 1. Text Search Logic
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(q);
        final brandMatch = p.brandName.toLowerCase().contains(q);
        final catMatch = p.categoryName.toLowerCase().contains(q);
        final skuMatch = p.sku.toLowerCase().contains(q);
        final descMatch = (p.description).toLowerCase().contains(q);
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(q));
        final keywordMatch = p.keywords.any((k) => k.toLowerCase().contains(q));

        if (!nameMatch && !brandMatch && !catMatch && !skuMatch && !descMatch && !tagMatch && !keywordMatch) {
          return false;
        }
      }

      // 2. Filters Logic
      final effectivePrice = (p.discountPrice != null && p.discountPrice! > 0)
          ? p.discountPrice!
          : p.price;
      if (effectivePrice < _filters.priceRange.start) {
        return false;
      }
      if (_filters.priceRange.end < 500000 &&
          effectivePrice > _filters.priceRange.end) {
        return false;
      }
      if (_filters.category != null && p.categoryName != _filters.category) {
        return false;
      }
      if (_filters.selectedBrands.isNotEmpty &&
          !_filters.selectedBrands.contains(p.brandName)) {
        return false;
      }
      if (_filters.minRating != null && p.averageRating < _filters.minRating!) {
        return false;
      }
      if (_filters.availability != null) {
        if (_filters.availability == 'in_stock' && p.stock <= 0) return false;
        if (_filters.availability == 'low_stock' &&
            (p.stock <= 0 || p.stock > p.minimumStock)) return false;
        if (_filters.availability == 'out_of_stock' && p.stock > 0) return false;
      }
      if (_filters.discountedOnly &&
          (p.discountPrice == null || p.discountPrice! <= 0)) {
        return false;
      }
      if (_filters.isFeatured && !p.isFeatured) return false;
      if (_filters.isBestSeller && !p.isBestSeller) return false;
      if (_filters.isNewArrival && !p.isNewArrival) return false;

      return true;
    }).toList()
      ..sort((a, b) {
        // 3. Sorting Logic
        switch (_selectedSort) {
          case SortOption.newest:
            return b.createdAt.compareTo(a.createdAt);
          case SortOption.oldest:
            return a.createdAt.compareTo(b.createdAt);
          case SortOption.priceLowToHigh:
            final pA = a.discountPrice ?? a.price;
            final pB = b.discountPrice ?? b.price;
            return pA.compareTo(pB);
          case SortOption.priceHighToLow:
            final pA = a.discountPrice ?? a.price;
            final pB = b.discountPrice ?? b.price;
            return pB.compareTo(pA);
          case SortOption.highestRated:
            return b.averageRating.compareTo(a.averageRating);
          case SortOption.mostPopular:
            return (b.soldCount ?? 0).compareTo(a.soldCount ?? 0);
          case SortOption.alphabeticalAZ:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.alphabeticalZA:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case SortOption.bestSeller:
            return (b.isBestSeller ? 1 : 0).compareTo(a.isBestSeller ? 1 : 0);
          case SortOption.featured:
            return (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
          case SortOption.newArrival:
            return (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0);
          case SortOption.highestDiscount:
            final diffA = a.price - (a.discountPrice ?? a.price);
            final diffB = b.price - (b.discountPrice ?? b.price);
            return diffB.compareTo(diffA);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final allProducts = provider.products.isNotEmpty
        ? provider.products
        : provider.activeProducts;
    final filteredProducts = _filterAndSortProducts(allProducts);

    final maxAvailablePrice = allProducts.isEmpty
        ? 100000.0
        : allProducts
            .map((p) => (p.discountPrice != null && p.discountPrice! > 0)
                ? p.discountPrice!
                : p.price)
            .fold(10000.0, (a, b) => a > b ? a : b);

    // Dynamic Lists for Filter Sheets
    final categories = allProducts
        .map((e) => e.categoryName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final brands = allProducts
        .map((e) => e.brandName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Component
            CustomSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              activeFilterCount: _countActiveFilters(),
              onOpenFilter: () {
                final safeMax = maxAvailablePrice > 0 ? maxAvailablePrice : 10000.0;
                final currentStart = _filters.priceRange.start.clamp(0.0, safeMax);
                final currentEnd = _filters.priceRange.end >= 500000
                    ? safeMax
                    : _filters.priceRange.end.clamp(currentStart, safeMax);
                final clampedFilters = _filters.copyWith(
                  priceRange: RangeValues(currentStart, currentEnd),
                );
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => FilterBottomSheet(
                    initialFilters: clampedFilters,
                    availableCategories: categories,
                    availableBrands: brands,
                    availableColors: const [
                      'Black',
                      'Silver',
                      'Gold',
                      'Blue',
                      'Brown'
                    ],
                    minPrice: 0,
                    maxPrice: safeMax,
                    onApply: (applied) => setState(() => _filters = applied),
                    onReset: _resetFilters,
                  ),
                );
              },
              onOpenSort: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SortBottomSheet(
                    selectedSort: _selectedSort,
                    onSelectSort: (sort) =>
                        setState(() => _selectedSort = sort),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Recent Search Terms
            if (_searchQuery.isEmpty && _countActiveFilters() == 0) ...[
              SearchHistory(
                history: _recentSearches,
                onSelectSearch: (term) {
                  _searchController.text = term;
                  _onSearchChanged(term);
                },
                onDeleteSearch: (term) {
                  setState(() => _recentSearches.remove(term));
                },
                onClearAll: () {
                  setState(() => _recentSearches.clear());
                },
              ),
              const SizedBox(height: 12),
            ],

            // Active Removable Filter Chips
            ActiveFilters(
              filters: _filters,
              onClearAll: _resetFilters,
              onRemoveFilter: _removeSingleFilter,
            ),

            // Search Results Heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results (${filteredProducts.length})',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedSort.displayName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Result Content
            Expanded(
              child: provider.isLoading
                  ? const SearchShimmer()
                  : filteredProducts.isEmpty
                      ? NoResultsWidget(onResetFilters: _resetFilters)
                      : SearchResultGrid(
                          products: filteredProducts,
                          currentUserId: currentUserId,
                          onProductTap: (product) {
                            _navigateToProductDetails(
                              context,
                              product,
                              currentUserId,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}