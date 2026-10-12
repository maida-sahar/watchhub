import 'dart:async';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../repositories/product_repository.dart';

/// Sort options supported by [ProductProvider.sortProducts].
///
/// NOTE: [latest] and [newest] are intentionally treated as aliases —
/// both mean "most recently created first" (`createdAt` descending).
/// The requested sort option list named them as two separate options,
/// but there's no other reasonable distinct meaning for "Latest" once
/// "Newest" and "Oldest" already cover the `createdAt` axis, so rather
/// than inventing an arbitrary difference between them, both resolve
/// to the same behavior here.
enum ProductSortOption {
  latest,
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
  mostPopular,
  alphabetical,
}

/// ProductProvider
///
/// Owns all Product-related UI state and is the ONLY layer the Admin
/// Panel and User App widgets should talk to for product data.
///
///   UI → ProductProvider → ProductRepository → ProductService → Firebase
///
/// This class never imports Firebase packages and never talks to
/// [ProductRepository]'s underlying service directly — it only calls
/// repository methods and translates the result (or failure) into
/// observable state via [ChangeNotifier].
class ProductProvider extends ChangeNotifier {
  /// [repository] is injected so this provider can be unit-tested with
  /// a fake/mock repository, without touching real Firebase.
  ProductProvider({required ProductRepository repository})
      : _repository = repository;

  final ProductRepository _repository;

  // =========================================================
  // STATE
  // =========================================================

  List<ProductModel> _products = [];
  List<ProductModel> _activeProducts = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _bestSellerProducts = [];
  List<ProductModel> _newArrivalProducts = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<ProductModel>>? _productsSubscription;
  bool _isWatchingAllProducts = false;


  // =========================================================
  // GETTERS
  // =========================================================

  /// All products (active and inactive) — used by the Admin Panel.
  List<ProductModel> get products => List.unmodifiable(_products);

  /// Only active products — used by the User App.
  List<ProductModel> get activeProducts => List.unmodifiable(_activeProducts);

  /// Active products flagged as featured.
  List<ProductModel> get featuredProducts =>
      List.unmodifiable(_featuredProducts);

  /// Products flagged as best sellers.
  List<ProductModel> get bestSellerProducts =>
      List.unmodifiable(_bestSellerProducts);

  /// Products flagged as new arrivals.
  List<ProductModel> get newArrivalProducts =>
      List.unmodifiable(_newArrivalProducts);

  /// The current "browsable" result set — populated by
  /// [loadProductsByCategory], [loadProductsByBrand], [searchProducts],
  /// [filterProducts], and [sortProducts]. Kept separate from
  /// [products] so a category/brand/search/filter view never disturbs
  /// the Admin Panel's full product list.
  List<ProductModel> get filteredProducts =>
      List.unmodifiable(_filteredProducts);

  /// The most recently loaded single product, if any.
  ProductModel? get selectedProduct => _selectedProduct;

  /// Whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  /// The last error message, or `null` if there is no active error.
  String? get errorMessage => _errorMessage;

  /// Convenience flag for UI to quickly check for an error state.
  bool get hasError => _errorMessage != null;

  // =========================================================
  // PUBLIC METHODS — LOADS
  // =========================================================

  /// Loads all products for the Admin Panel.
  Future<void> loadProducts() async {
    await _runGuarded(() async {
      _products = await _repository.getAllProducts();
    });
  }

  /// Loads only active products for the User App.
  Future<void> loadActiveProducts() async {
    await _runGuarded(() async {
      _activeProducts = await _repository.getActiveProducts();
    });
  }

  /// Loads active products flagged as featured.
  Future<void> loadFeaturedProducts() async {
    await _runGuarded(() async {
      _featuredProducts = await _repository.getFeaturedProducts();
    });
  }

  /// Loads products flagged as best sellers.
  Future<void> loadBestSellerProducts() async {
    await _runGuarded(() async {
      _bestSellerProducts = await _repository.getBestSellerProducts();
    });
  }

  /// Loads products flagged as new arrivals.
  Future<void> loadNewArrivalProducts() async {
    await _runGuarded(() async {
      _newArrivalProducts = await _repository.getNewArrivalProducts();
    });
  }

  /// Loads all products in [categoryId] into [filteredProducts] — e.g.
  /// for a "Browse Category" screen.
  Future<void> loadProductsByCategory(String categoryId) async {
    await _runGuarded(() async {
      _filteredProducts = await _repository.getProductsByCategory(categoryId);
    });
  }

  /// Loads all products for [brandId] into [filteredProducts] — e.g.
  /// for a "Browse Brand" screen.
  Future<void> loadProductsByBrand(String brandId) async {
    await _runGuarded(() async {
      _filteredProducts = await _repository.getProductsByBrand(brandId);
    });
  }

  /// Loads a single product by [id] and stores it in [selectedProduct].
  Future<void> loadProductById(String id) async {
    await _runGuarded(() async {
      _selectedProduct = await _repository.getProductById(id);
    });
  }

  // =========================================================
  // PUBLIC METHODS — IDS
  // =========================================================

  /// Reserves a new product id, needed before uploading images for a
  /// not-yet-created product. See
  /// [ProductRepository.generateProductId] for why this exists.
  String generateProductId() => _repository.generateProductId();

  // =========================================================
  // PUBLIC METHODS — MUTATIONS
  // =========================================================

  /// Creates a new product.
  Future<bool> createProduct(
    ProductModel product, {
    required XFile thumbnailFile,
    required List<XFile> galleryFiles,
  }) {
    return _runGuardedBool(() async {
      await _repository.createProduct(
        product,
        thumbnailFile: thumbnailFile,
        galleryFiles: galleryFiles,
      );
      await _refreshAllLists();
    });
  }

  /// Updates an existing product.
  Future<bool> updateProduct(
    ProductModel product, {
    XFile? newThumbnailFile,
    List<XFile>? newGalleryFiles,
  }) {
    return _runGuardedBool(() async {
      await _repository.updateProduct(
        product,
        newThumbnailFile: newThumbnailFile,
        newGalleryFiles: newGalleryFiles,
      );
      await _refreshAllLists();
    });
  }

  /// Deletes a product, then refreshes every cached product list.
  Future<bool> deleteProduct(String productId) {
    return _runGuardedBool(() async {
      await _repository.deleteProduct(productId);
      await _refreshAllLists();
      if (_selectedProduct?.id == productId) {
        _selectedProduct = null;
      }
    });
  }

  // =========================================================
  // PUBLIC METHODS — INVENTORY
  // =========================================================

  /// Sets a product's absolute stock count.
  ///
  /// Unlike [createProduct]/[updateProduct], this does NOT re-fetch
  /// every list — changing `stock` never changes which list a product
  /// belongs to, so only that single product is patched in place
  /// across [selectedProduct] and every cached list, avoiding five
  /// unnecessary Firestore reads for a routine stock change.
  Future<bool> updateStock(String productId, int stock) {
    return _runGuardedBool(() async {
      await _repository.updateStock(productId, stock);
      await _refreshSingleProduct(productId);
    });
  }

  /// Atomically increases a product's sold count by [quantity].
  ///
  /// Same reasoning as [updateStock]: only the single affected product
  /// is refreshed, not every list.
  Future<bool> increaseSoldCount(String productId, int quantity) {
    return _runGuardedBool(() async {
      await _repository.increaseSoldCount(productId, quantity);
      await _refreshSingleProduct(productId);
    });
  }

  // =========================================================
  // PUBLIC METHODS — PRODUCT STATUS
  // =========================================================

  /// Enables or disables a product, then refreshes every cached list.
  ///
  /// A full list refresh (rather than an in-place patch) is used here
  /// — unlike [updateStock]/[increaseSoldCount] — because toggling
  /// `isActive` changes whether the product should appear in
  /// [activeProducts]/[featuredProducts] at all, not just one of its
  /// field values.
  Future<bool> toggleProductStatus(String productId, bool isActive) {
    return _runGuardedBool(() async {
      await _repository.toggleProductStatus(productId, isActive);
      await _refreshAllLists();
    });
  }

  /// Toggles a product's featured flag, then refreshes every cached
  /// list (list membership of [featuredProducts] can change).
  Future<bool> toggleFeatured(String productId, bool isFeatured) {
    return _runGuardedBool(() async {
      await _repository.toggleFeatured(productId, isFeatured);
      await _refreshAllLists();
    });
  }

  /// Toggles a product's best-seller flag, then refreshes every cached
  /// list (list membership of [bestSellerProducts] can change).
  Future<bool> toggleBestSeller(String productId, bool isBestSeller) {
    return _runGuardedBool(() async {
      await _repository.toggleBestSeller(productId, isBestSeller);
      await _refreshAllLists();
    });
  }

  /// Toggles a product's new-arrival flag, then refreshes every cached
  /// list (list membership of [newArrivalProducts] can change).
  Future<bool> toggleNewArrival(String productId, bool isNewArrival) {
    return _runGuardedBool(() async {
      await _repository.toggleNewArrival(productId, isNewArrival);
      await _refreshAllLists();
    });
  }

  // =========================================================
  // PUBLIC METHODS — SEARCH / FILTER / SORT
  // =========================================================

  /// Performs an in-memory, case-insensitive search over the already
  /// loaded [products] list (name, brand name, category name, tags,
  /// and keywords) — this NEVER queries Firestore, so it's safe to
  /// call on every keystroke of a search field.
  ///
  /// Stores the result in [filteredProducts] and also returns it
  /// directly, so callers can either react to [filteredProducts]
  /// changing or use the return value immediately.
  List<ProductModel> searchProducts(String keyword) {
    final trimmedKeyword = keyword.trim().toLowerCase();
    final results = trimmedKeyword.isEmpty
        ? List<ProductModel>.from(_products)
        : _products.where((product) {
            if (product.name.toLowerCase().contains(trimmedKeyword)) {
              return true;
            }
            if (product.brandName.toLowerCase().contains(trimmedKeyword)) {
              return true;
            }
            if (product.categoryName.toLowerCase().contains(trimmedKeyword)) {
              return true;
            }
            if (product.tags
                .any((t) => t.toLowerCase().contains(trimmedKeyword))) {
              return true;
            }
            if (product.keywords
                .any((k) => k.toLowerCase().contains(trimmedKeyword))) {
              return true;
            }
            return false;
          }).toList();

    _filteredProducts = results;
    notifyListeners();
    return List.unmodifiable(results);
  }

  /// Filters the already-loaded [products] list by any combination of
  /// [categoryId], [brandId], price range ([minPrice]/[maxPrice]),
  /// [minRating], [inStockOnly] (availability), [isFeatured],
  /// [isBestSeller], and [isNewArrival]. Every provided criterion is
  /// combined with AND; omitted (`null`) criteria are ignored.
  ///
  /// Like [searchProducts], this operates entirely in-memory — it
  /// never queries Firestore. Stores the result in [filteredProducts]
  /// and also returns it directly.
  List<ProductModel> filterProducts({
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStockOnly,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
  }) {
    final results = _products.where((product) {
      if (categoryId != null && product.categoryId != categoryId) {
        return false;
      }
      if (brandId != null && product.brandId != brandId) return false;
      if (minPrice != null && product.discountPrice < minPrice) return false;
      if (maxPrice != null && product.discountPrice > maxPrice) return false;
      if (minRating != null && product.averageRating < minRating) {
        return false;
      }
      if (inStockOnly == true && product.stock <= 0) return false;
      if (isFeatured != null && product.isFeatured != isFeatured) {
        return false;
      }
      if (isBestSeller != null && product.isBestSeller != isBestSeller) {
        return false;
      }
      if (isNewArrival != null && product.isNewArrival != isNewArrival) {
        return false;
      }
      return true;
    }).toList();

    _filteredProducts = results;
    notifyListeners();
    return List.unmodifiable(results);
  }

  /// Sorts the current [filteredProducts] view by [option].
  ///
  /// If no filter/search has been applied yet (i.e. [filteredProducts]
  /// is empty), this sorts a fresh copy of the full [products] list
  /// instead and uses that as the new [filteredProducts] — so
  /// "sort with no filter applied" still works as expected rather than
  /// silently doing nothing.
  List<ProductModel> sortProducts(ProductSortOption option) {
    final source = _filteredProducts.isNotEmpty
        ? List<ProductModel>.from(_filteredProducts)
        : List<ProductModel>.from(_products);

    switch (option) {
      case ProductSortOption.latest:
      case ProductSortOption.newest:
        source.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortOption.oldest:
        source.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ProductSortOption.priceLowToHigh:
        source.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
        break;
      case ProductSortOption.priceHighToLow:
        source.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
        break;
      case ProductSortOption.highestRated:
        source.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case ProductSortOption.mostPopular:
        source.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      case ProductSortOption.alphabetical:
        source.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    _filteredProducts = source;
    notifyListeners();
    return List.unmodifiable(source);
  }

  /// Clears any active search/filter/sort result, resetting
  /// [filteredProducts] back to empty.
  void clearFilters() {
    if (_filteredProducts.isEmpty) return;
    _filteredProducts = [];
    notifyListeners();
  }

  /// Clears the active error state.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Refreshes all five cached product lists in parallel. Used after
  /// any mutation that can change a product's flags (and therefore
  /// which lists it belongs to): create, update, delete, and every
  /// status toggle.
  Future<void> _refreshAllLists() async {
    final results = await Future.wait([
      _repository.getAllProducts(),
      _repository.getActiveProducts(),
      _repository.getFeaturedProducts(),
      _repository.getBestSellerProducts(),
      _repository.getNewArrivalProducts(),
    ]);
    _products = results[0];
    _activeProducts = results[1];
    _featuredProducts = results[2];
    _bestSellerProducts = results[3];
    _newArrivalProducts = results[4];
  }

  /// Re-fetches a single product and patches it into [selectedProduct]
  /// and every cached list that currently contains it, in place — used
  /// after a mutation (stock change, sold-count increment) that never
  /// changes which list the product belongs to, so a full
  /// [_refreshAllLists] round-trip isn't needed.
  Future<void> _refreshSingleProduct(String productId) async {
    final updated = await _repository.getProductById(productId);
    if (updated == null) return;

    if (_selectedProduct?.id == productId) {
      _selectedProduct = updated;
    }
    _products = _replaceInList(_products, updated);
    _activeProducts = _replaceInList(_activeProducts, updated);
    _featuredProducts = _replaceInList(_featuredProducts, updated);
    _bestSellerProducts = _replaceInList(_bestSellerProducts, updated);
    _newArrivalProducts = _replaceInList(_newArrivalProducts, updated);
    _filteredProducts = _replaceInList(_filteredProducts, updated);
  }

  /// Returns a new list with any entry matching [updated]'s id
  /// replaced by [updated]. Leaves the list unchanged (aside from the
  /// copy) if no matching entry is found.
  List<ProductModel> _replaceInList(
    List<ProductModel> list,
    ProductModel updated,
  ) {
    final index = list.indexWhere((p) => p.id == updated.id);
    if (index == -1) return list;
    final copy = List<ProductModel>.from(list);
    copy[index] = updated;
    return copy;
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runGuardedBool(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var success = false;
    try {
      await action();
      success = true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }



  String _extractMessage(Object error) {
    if (error is ProductRepositoryException) {
      return error.message;
    }
    return 'Something went wrong while processing products. Please try again.';
  }

  /// Subscribes to real-time updates for all products.
  void watchAllProducts() {
    if (_isWatchingAllProducts && _productsSubscription != null) return;
    _isWatchingAllProducts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _productsSubscription?.cancel();
    _productsSubscription = _repository.watchAllProducts().listen(
      (updatedProducts) {
        _products = updatedProducts;
        _activeProducts = updatedProducts.where((p) => p.isActive).toList();
        _featuredProducts = updatedProducts.where((p) => p.isFeatured && p.isActive).toList();
        _bestSellerProducts = updatedProducts.where((p) => p.isBestSeller).toList();
        _newArrivalProducts = updatedProducts.where((p) => p.isNewArrival).toList();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to stream products: $error';
        _isLoading = false;
        _isWatchingAllProducts = false;
        notifyListeners();
      },
    );
  }

  /// Cancels the product stream subscription.
  void stopWatchingProducts() {
    _isWatchingAllProducts = false;
    _productsSubscription?.cancel();
    _productsSubscription = null;
  }

  @override
  void dispose() {
    stopWatchingProducts();
    super.dispose();
  }
}
