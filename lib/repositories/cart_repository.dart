import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import 'wishlist_repository.dart';

/// Exceptions specific to high-level Repository operations.
class CartException implements Exception {
  final String message;
  const CartException(this.message);

  @override
  String toString() => message;
}

/// Firestore implementation of Cart Repository.
///
/// Follows Clean Architecture:
/// • Communicates strictly with [CartService] (Service layer).
/// • Does not import cloud_firestore or firebase_auth directly.
/// • Implements [ICartRepositoryStub] for cross-module integration with Wishlist.
class CartRepository implements ICartRepositoryStub {
  final CartService _service;

  CartRepository({required CartService service}) : _service = service;

  /// Retrieves a real-time stream of the user's cart items.
  Stream<List<CartModel>> watchCart(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value([]);
    }
    return _service.watchCart(userId);
  }

  /// Retrieves a list of cart items once.
  Future<List<CartModel>> getUserCart(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      return await _service.getUserCart(userId);
    } catch (e) {
      throw CartException('Failed to fetch user cart: ${e.toString()}');
    }
  }

  /// Checks if a product exists in the user's cart.
  @override
  Future<bool> isProductInCart(String userId, String productId) async {
    if (userId.trim().isEmpty || productId.trim().isEmpty) return false;
    try {
      final item = await _service.getCartItem(userId, productId);
      return item != null;
    } catch (e) {
      throw CartException('Failed to check product cart status: ${e.toString()}');
    }
  }

  /// Adds a product to the user's cart with business rules validation.
  @override
  Future<void> addToCart(
    String userId,
    ProductModel product, {
    int quantity = 1,
  }) async {
    // 1. Validation checks
    if (userId.trim().isEmpty) {
      throw const CartException('Authentication required. Please log in.');
    }
    if (!product.isActive) {
      throw const CartException('This product is inactive and cannot be purchased.');
    }
    if (product.stock <= 0) {
      throw const CartException('Selected product is currently out of stock.');
    }
    if (quantity <= 0) {
      throw const CartException('Quantity must be greater than zero.');
    }
    if (quantity > product.stock) {
      throw CartException('Cannot add more than available stock (${product.stock}).');
    }

    final cartItem = CartModel(
      id: '', // Service will auto-generate
      userId: userId,
      productId: product.id,
      productName: product.name,
      productImage: product.thumbnail.isNotEmpty
          ? product.thumbnail
          : (product.galleryImages.isNotEmpty ? product.galleryImages.first : ''),
      brandId: product.brandId,
      brandName: product.brandName,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      price: product.price,
      discountPrice: product.discountPrice,
      quantity: quantity,
      maxQuantity: 5, // Standard purchasing limit
      stock: product.stock,
      averageRating: product.averageRating,
      isActive: product.isActive,
      isInStock: product.stock > 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _service.addToCart(cartItem);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Validates a product's quantity directly against Firestore state.
  Future<void> validateQuantity(String productId, int quantity) async {
    try {
      await _service.validateQuantity(productId, quantity);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Fetches available stock for a product from the database.
  Future<int> getAvailableStock(String productId) async {
    try {
      return await _service.getAvailableStock(productId);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Updates the quantity of a specific cart item.
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      await _service.updateQuantity(cartItemId, quantity);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Increments quantity by 1.
  Future<void> increaseQuantity(String cartItemId) async {
    try {
      await _service.increaseQuantity(cartItemId);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Decrements quantity by 1.
  Future<void> decreaseQuantity(String cartItemId) async {
    try {
      await _service.decreaseQuantity(cartItemId);
    } catch (e) {
      throw CartException(e.toString().replaceAll('CartServiceException: ', ''));
    }
  }

  /// Removes an item from the cart.
  Future<void> removeItem(String cartItemId) async {
    try {
      await _service.removeFromCart(cartItemId);
    } catch (e) {
      throw CartException('Failed to remove item from cart: ${e.toString()}');
    }
  }

  /// Clears the user's cart.
  Future<void> clearCart(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await _service.clearCart(userId);
    } catch (e) {
      throw CartException('Failed to clear cart: ${e.toString()}');
    }
  }
}
