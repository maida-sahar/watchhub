import '../models/product_model.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_service.dart';

/// Repository interface for Cart operations required for Wishlist integration.
abstract class ICartRepositoryStub {
  Future<bool> isProductInCart(String userId, String productId);
  Future<void> addToCart(String userId, ProductModel product, {int quantity = 1});
}

/// Firestore implementation of Wishlist Repository.
///
/// Follows Clean Architecture:
/// • Communicates strictly with [WishlistService] (Service layer).
/// • Does not import cloud_firestore or firebase_auth directly.
class WishlistRepository {
  final WishlistService _service;

  WishlistRepository({required WishlistService service}) : _service = service;

  /// Retrieves a real-time stream of the user's wishlist.
  Stream<List<WishlistModel>> watchWishlist(String userId) {
    return _service.watchWishlist(userId);
  }

  /// Removes an item from the user's wishlist in Firestore.
  Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      await _service.removeProductFromWishlist(userId, productId);
    } catch (e) {
      throw Exception('Failed to remove item from wishlist: $e');
    }
  }

  /// Adds a product to the user's wishlist in Firestore.
  Future<void> addToWishlist({
    required String userId,
    required ProductModel product,
  }) async {
    final wishlist = WishlistModel(
      id: '', // Service will auto-generate the document ID
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
      averageRating: product.averageRating,
      isInStock: product.stock > 0,
      isActive: product.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _service.addToWishlist(wishlist);
    } catch (e) {
      throw Exception('Failed to add item to wishlist: $e');
    }
  }

  /// Transfers a product from Wishlist to Cart.
  /// Integrates with [ICartRepositoryStub] when Cart Module is provided.
  Future<void> moveToCart({
    required String userId,
    required ProductModel product,
    ICartRepositoryStub? cartRepository,
  }) async {
    try {
      // 1. Check if item already exists in cart if repo provided
      if (cartRepository != null) {
        final exists = await cartRepository.isProductInCart(userId, product.id);
        if (exists) {
          throw Exception('This product is already in your cart.');
        }
        await cartRepository.addToCart(userId, product);
      }

      // 2. Remove item from Wishlist collection
      await removeFromWishlist(userId: userId, productId: product.id);
    } catch (e) {
      rethrow;
    }
  }
}