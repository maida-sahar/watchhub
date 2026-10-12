import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/wishlist_model.dart';
import '../repositories/wishlist_repository.dart';
import '../services/wishlist_service.dart';

/// Custom Exception types for clear error mapping in UI
class WishlistException implements Exception {
  final String message;
  WishlistException(this.message);

  @override
  String toString() => message;
}

class DuplicateCartItemException implements Exception {
  final String message;
  DuplicateCartItemException([this.message = 'This product is already in your cart.']);

  @override
  String toString() => message;
}

class OutOfStockException implements Exception {
  final String message;
  OutOfStockException([this.message = 'Selected product is out of stock.']);

  @override
  String toString() => message;
}

class WishlistProvider extends ChangeNotifier {
  final WishlistRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<WishlistModel>>? _wishlistSubscription;

  List<ProductModel> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Track per-item processing state for operations
  final Map<String, bool> _itemProcessingStates = {};

  WishlistProvider({WishlistRepository? repository})
      : _repository = repository ?? WishlistRepository(service: WishlistService()) {
    // Automatically listen to auth changes to bind/unbind wishlist stream
    _listenToAuthChanges();
  }

  List<ProductModel> get wishlistItems => List.unmodifiable(_wishlistItems);
  int get wishlistCount => _wishlistItems.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isItemProcessing(String productId) => _itemProcessingStates[productId] ?? false;

  bool checkWishlistStatusLocally(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  /// Sets up initial wishlist data manually if needed (primarily for fallback/tests)
  void setWishlistItems(List<ProductModel> items) {
    _wishlistItems = List.from(items);
    notifyListeners();
  }

  /// Listens to auth state changes to start/stop the wishlist real-time subscription
  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToWishlist(user.uid);
      } else {
        _unsubscribeAndClear();
      }
    });
  }

  /// Subscribes to the real-time wishlist stream from the repository
  void _subscribeToWishlist(String userId) {
    _wishlistSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _wishlistSubscription = _repository.watchWishlist(userId).listen(
      (wishlistModels) {
        _wishlistItems = wishlistModels.map((item) => _mapWishlistToProduct(item)).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Cancels subscription and clears local cache upon sign-out
  void _unsubscribeAndClear() {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = null;
    _wishlistItems = [];
    _isLoading = false;
    _errorMessage = null;
    _itemProcessingStates.clear();
    notifyListeners();
  }

  /// Maps [WishlistModel] to [ProductModel] for display in listing/details screens
  ProductModel _mapWishlistToProduct(WishlistModel wishlist) {
    return ProductModel(
      id: wishlist.productId,
      name: wishlist.productName,
      thumbnail: wishlist.productImage,
      brandId: wishlist.brandId,
      brandName: wishlist.brandName,
      categoryId: wishlist.categoryId,
      categoryName: wishlist.categoryName,
      price: wishlist.price,
      discountPrice: wishlist.discountPrice,
      averageRating: wishlist.averageRating,
      galleryImages: [wishlist.productImage],
      sku: 'SKU-${wishlist.productId}',
      stock: wishlist.isInStock ? 10 : 0,
      isActive: wishlist.isActive,
      createdAt: wishlist.createdAt,
      updatedAt: wishlist.updatedAt,
    );
  }

  /// Toggles a product in/out of the wishlist (Add or Remove)
  Future<void> toggleWishlist({
    required String userId,
    required ProductModel product,
  }) async {
    if (userId.isEmpty) return;

    final isInWishlist = checkWishlistStatusLocally(product.id);

    if (isInWishlist) {
      await removeFromWishlist(userId: userId, productId: product.id);
    } else {
      await addToWishlist(userId: userId, product: product);
    }
  }

  /// Adds a product to the wishlist
  Future<void> addToWishlist({
    required String userId,
    required ProductModel product,
  }) async {
    _setProcessing(product.id, true);
    _errorMessage = null;
    try {
      await _repository.addToWishlist(userId: userId, product: product);
      // Local optimistic update
      if (!checkWishlistStatusLocally(product.id)) {
        _wishlistItems.add(product);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(product.id, false);
    }
  }

  /// Removes product from local list and Firestore
  Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    _setProcessing(productId, true);
    _errorMessage = null;
    try {
      await _repository.removeFromWishlist(userId: userId, productId: productId);
      // Local optimistic update
      _wishlistItems.removeWhere((item) => item.id == productId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(productId, false);
    }
  }

  /// Handles the Move To Cart business logic, validation, and state synchronization.
  Future<void> moveToCart({
    required String userId,
    required ProductModel product,
    Future<bool> Function(ProductModel product)? onAddToCartDelegate,
  }) async {
    // 1. Validation checks
    if (userId.isEmpty) {
      throw WishlistException('User authentication required.');
    }

    if (product.stock <= 0) {
      throw OutOfStockException('This product is currently out of stock.');
    }

    _setProcessing(product.id, true);
    _errorMessage = null;

    try {
      // 2. Add to Cart via Delegate (if CartProvider present)
      if (onAddToCartDelegate != null) {
        final success = await onAddToCartDelegate(product);
        if (!success) {
          throw DuplicateCartItemException('This product is already in your cart.');
        }
      }

      // 3. Delete from Wishlist Firestore collection
      await _repository.removeFromWishlist(userId: userId, productId: product.id);

      // 4. Update local Wishlist state
      _wishlistItems.removeWhere((item) => item.id == product.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(product.id, false);
    }
  }

  void _setProcessing(String productId, bool value) {
    _itemProcessingStates[productId] = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _wishlistSubscription?.cancel();
    super.dispose();
  }
}