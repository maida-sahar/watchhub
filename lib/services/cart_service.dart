import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';

/// Exception wrapper for all [CartService] operation failures.
class CartServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const CartServiceException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() =>
      'CartServiceException: $message ${code != null ? '($code)' : ''}';
}

/// [CartService] manages low-level Firestore operations for the shopping cart.
///
/// Follows Clean Architecture:
/// • Communicates strictly with Firebase Firestore (`carts` collection).
/// • Handles type conversions, error mapping, and transaction/batch operations.
class CartService {
  final FirebaseFirestore _firestore;

  /// Firestore Collection Paths
  static const String _collectionPath = 'carts';
  static const String _productsCollection = 'products';
  static const String _usersCollection = 'users';

  /// Dependency Injection constructor for testability.
  CartService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cartRef =>
      _firestore.collection(_collectionPath);

  // =========================================================
  // READ OPERATIONS
  // =========================================================

  /// Retrieves all cart items for a specific [userId] ordered by creation date descending.
  Future<List<CartModel>> getUserCart(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final snapshot = await _cartRef
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => CartModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'fetching user cart');
    } catch (e) {
      throw _handleGenericException(e, 'fetching user cart');
    }
  }

  /// Fetches a specific cart item document for a given [userId] and [productId].
  Future<CartModel?> getCartItem(
    String userId,
    String productId,
  ) async {
    _validateNonEmpty(userId, fieldName: 'userId');
    _validateNonEmpty(productId, fieldName: 'productId');

    try {
      final snapshot = await _cartRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return CartModel.fromMap(doc.data(), documentId: doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'fetching cart item');
    } catch (e) {
      throw _handleGenericException(e, 'fetching cart item');
    }
  }

  /// Returns the sum of quantities of all cart items for a given [userId].
  Future<int> getCartCount(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final cartItems = await getUserCart(userId);
      return cartItems.fold<int>(0, (total, item) => total + item.quantity);
    } catch (e) {
      throw _handleGenericException(e, 'calculating cart item count');
    }
  }

  /// Returns the sum of `price * quantity` (Subtotal before discounts) for a user.
  Future<double> getCartSubtotal(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final cartItems = await getUserCart(userId);
      return cartItems.fold<double>(0.0, (total, item) => total + (item.price * item.quantity));
    } catch (e) {
      throw _handleGenericException(e, 'calculating cart subtotal');
    }
  }

  /// Returns the sum of `discountPrice * quantity` (Grand total after discounts) for a user.
  Future<double> getCartTotal(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final cartItems = await getUserCart(userId);
      return cartItems.fold<double>(0.0, (total, item) => total + (item.discountPrice * item.quantity));
    } catch (e) {
      throw _handleGenericException(e, 'calculating cart total');
    }
  }

  /// Fetches current available stock from the database for a specific product.
  Future<int> getAvailableStock(String productId) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw const CartServiceException(
          'Product not found.',
          code: 'product-not-found',
        );
      }
      return (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'getting available stock');
    } catch (e) {
      throw _handleGenericException(e, 'getting available stock');
    }
  }

  // =========================================================
  // STREAM SUPPORT
  // =========================================================

  /// Listens to real-time updates for a user's cart items.
  Stream<List<CartModel>> watchCart(String userId) {
    _validateNonEmpty(userId, fieldName: 'userId');

    return _cartRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CartModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      if (error is FirebaseException) {
        throw _handleFirebaseException(error, 'watching cart stream');
      }
      throw _handleGenericException(error, 'watching cart stream');
    });
  }

  // =========================================================
  // CREATE/ADD OPERATIONS
  // =========================================================

  /// Adds an item to the cart or increments quantity if it already exists.
  /// Validates user existence, product existence, and activity status.
  Future<void> addToCart(CartModel cartItem) async {
    _validateNonEmpty(cartItem.userId, fieldName: 'userId');
    _validateNonEmpty(cartItem.productId, fieldName: 'productId');

    try {
      // 1. Verify User Exists
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(cartItem.userId)
          .get();

      if (!userDoc.exists) {
        throw const CartServiceException(
          'Target user does not exist.',
          code: 'user-not-found',
        );
      }

      // 2. Verify Product Exists and is Active & In Stock
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(cartItem.productId)
          .get();

      if (!productDoc.exists) {
        throw const CartServiceException(
          'Target product does not exist.',
          code: 'product-not-found',
        );
      }

      final productData = productDoc.data();
      final bool isActive = productData?['isActive'] as bool? ?? false;
      final int stock = (productData?['stock'] as num?)?.toInt() ?? 0;

      if (!isActive) {
        throw const CartServiceException(
          'Cannot add an inactive product to cart.',
          code: 'product-inactive',
        );
      }

      if (stock <= 0) {
        throw const CartServiceException(
          'Product is currently out of stock.',
          code: 'out-of-stock',
        );
      }

      // 3. Check for Duplicate Product in User's Cart
      final existingItem = await getCartItem(cartItem.userId, cartItem.productId);

      if (existingItem != null) {
        // If duplicate, increase quantity instead of creating a new document
        final newQuantity = existingItem.quantity + cartItem.quantity;

        if (newQuantity > stock) {
          throw CartServiceException(
            'Cannot add more. Requested quantity ($newQuantity) exceeds available stock ($stock).',
            code: 'insufficient-stock',
          );
        }

        if (newQuantity > existingItem.maxQuantity) {
          throw CartServiceException(
            'Cannot add more. Quantity exceeds maximum allowed limit (${existingItem.maxQuantity}).',
            code: 'max-limit-exceeded',
          );
        }

        await updateQuantity(existingItem.id, newQuantity);
      } else {
        // Verify requested quantity against stock
        if (cartItem.quantity > stock) {
          throw CartServiceException(
            'Requested quantity (${cartItem.quantity}) exceeds available stock ($stock).',
            code: 'insufficient-stock',
          );
        }

        // 4. Perform Write
        final docRef = cartItem.id.isNotEmpty
            ? _cartRef.doc(cartItem.id)
            : _cartRef.doc();

        final now = DateTime.now();
        final dataToWrite = cartItem
            .copyWith(
              id: docRef.id,
              stock: stock, // Ensure latest stock value is saved
              createdAt: now,
              updatedAt: now,
            )
            .toMap();

        await docRef.set(dataToWrite);
      }
    } on CartServiceException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'adding item to cart');
    } catch (e) {
      throw _handleGenericException(e, 'adding item to cart');
    }
  }

  // =========================================================
  // VALIDATION METHODS
  // =========================================================

  /// Validates quantity parameters against Firestore product stock state.
  Future<void> validateQuantity(String productId, int quantity) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    if (quantity <= 0) {
      throw const CartServiceException(
        'Requested quantity must be greater than zero.',
        code: 'invalid-quantity',
      );
    }

    try {
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw const CartServiceException(
          'Product does not exist.',
          code: 'product-not-found',
        );
      }

      final productData = productDoc.data();
      final bool isActive = productData?['isActive'] as bool? ?? false;
      final int stock = (productData?['stock'] as num?)?.toInt() ?? 0;

      if (!isActive) {
        throw const CartServiceException(
          'Cannot purchase. This product is currently inactive.',
          code: 'product-inactive',
        );
      }

      if (stock <= 0) {
        throw const CartServiceException(
          'Cannot purchase. Selected product is currently out of stock.',
          code: 'out-of-stock',
        );
      }

      if (quantity > stock) {
        throw CartServiceException(
          'Cannot update quantity. Only $stock units are available in stock.',
          code: 'insufficient-stock',
        );
      }
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'validating quantity');
    } catch (e) {
      throw _handleGenericException(e, 'validating quantity');
    }
  }

  // =========================================================
  // UPDATE OPERATIONS
  // =========================================================

  /// Updates the quantity of a cart item directly.
  /// If the quantity becomes 0 or less, automatically removes it from the cart.
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    _validateNonEmpty(cartItemId, fieldName: 'cartItemId');
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      final docRef = _cartRef.doc(cartItemId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw const CartServiceException(
          'Cart item document not found.',
          code: 'document-not-found',
        );
      }

      final data = docSnap.data()!;
      final productId = data['productId'] as String? ?? '';
      
      // Perform validation check against Firestore
      await validateQuantity(productId, newQuantity);

      // Verify and update stock state in the cart document
      final latestStock = await getAvailableStock(productId);

      await docRef.update({
        'quantity': newQuantity,
        'stock': latestStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on CartServiceException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'updating cart item quantity');
    } catch (e) {
      throw _handleGenericException(e, 'updating cart item quantity');
    }
  }

  /// Increments quantity of a cart item by 1.
  Future<void> increaseQuantity(String cartItemId) async {
    _validateNonEmpty(cartItemId, fieldName: 'cartItemId');

    try {
      final docSnap = await _cartRef.doc(cartItemId).get();
      if (!docSnap.exists) {
        throw const CartServiceException(
          'Cart item document not found.',
          code: 'document-not-found',
        );
      }

      final currentQty = (docSnap.data()?['quantity'] as num?)?.toInt() ?? 1;
      await updateQuantity(cartItemId, currentQty + 1);
    } on CartServiceException {
      rethrow;
    } catch (e) {
      throw _handleGenericException(e, 'increasing quantity');
    }
  }

  /// Decrements quantity of a cart item by 1.
  /// If it goes below 1, it automatically triggers deletion.
  Future<void> decreaseQuantity(String cartItemId) async {
    _validateNonEmpty(cartItemId, fieldName: 'cartItemId');

    try {
      final docSnap = await _cartRef.doc(cartItemId).get();
      if (!docSnap.exists) {
        throw const CartServiceException(
          'Cart item document not found.',
          code: 'document-not-found',
        );
      }

      final currentQty = (docSnap.data()?['quantity'] as num?)?.toInt() ?? 1;
      await updateQuantity(cartItemId, currentQty - 1);
    } on CartServiceException {
      rethrow;
    } catch (e) {
      throw _handleGenericException(e, 'decreasing quantity');
    }
  }

  // =========================================================
  // DELETE OPERATIONS
  // =========================================================

  /// Removes a cart item by its document [cartItemId].
  Future<void> removeFromCart(String cartItemId) async {
    _validateNonEmpty(cartItemId, fieldName: 'cartItemId');

    try {
      await _cartRef.doc(cartItemId).delete();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'removing item from cart');
    } catch (e) {
      throw _handleGenericException(e, 'removing item from cart');
    }
  }

  /// Clears all cart items for a given [userId] using a batched write.
  Future<void> clearCart(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final snapshot =
          await _cartRef.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'clearing user cart');
    } catch (e) {
      throw _handleGenericException(e, 'clearing user cart');
    }
  }

  // =========================================================
  // PRIVATE EXCEPTION & VALIDATION HELPERS
  // =========================================================

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw CartServiceException(
        '$fieldName cannot be empty.',
        code: 'invalid-argument',
      );
    }
  }

  CartServiceException _handleFirebaseException(
    FirebaseException e,
    String context,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return CartServiceException(
          'Permission denied while $context.',
          code: 'permission-denied',
          details: e.message,
        );
      case 'unavailable':
      case 'network-request-failed':
        return CartServiceException(
          'Network connection failure while $context. Please check your internet connection.',
          code: 'network-failure',
          details: e.message,
        );
      case 'unauthenticated':
        return CartServiceException(
          'User is unauthenticated. Please log in again.',
          code: 'unauthenticated',
          details: e.message,
        );
      case 'not-found':
        return CartServiceException(
          'Requested document not found.',
          code: 'document-not-found',
          details: e.message,
        );
      case 'already-exists':
        return CartServiceException(
          'Document already exists.',
          code: 'duplicate-item',
          details: e.message,
        );
      default:
        return CartServiceException(
          'Firestore operation failed while $context: ${e.message ?? e.code}',
          code: e.code,
          details: e,
        );
    }
  }

  CartServiceException _handleGenericException(
    Object error,
    String context,
  ) {
    if (error is CartServiceException) return error;

    return CartServiceException(
      'An unexpected error occurred while $context.',
      code: 'unknown-error',
      details: error,
    );
  }
}
