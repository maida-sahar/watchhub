import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wishlist_model.dart';

/// Exception wrapper for all [WishlistService] operation failures.
class WishlistServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const WishlistServiceException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() =>
      'WishlistServiceException: $message ${code != null ? '($code)' : ''}';
}

/// [WishlistService] manages low-level Firestore operations for user wishlists.
///
/// Follows Clean Architecture standards:
/// • Communicates strictly with Firebase Firestore (`wishlists` collection).
/// • Contains ZERO UI logic, Provider logic, or high-level business rules.
/// • Handles type conversions, error mapping, and transaction/batch operations.
class WishlistService {
  final FirebaseFirestore _firestore;

  /// Firestore Collection Path for Wishlist documents.
  static const String _collectionPath = 'wishlists';
  static const String _productsCollection = 'products';
  static const String _usersCollection = 'users';

  /// Dependency Injection constructor for testability.
  WishlistService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _wishlistRef =>
      _firestore.collection(_collectionPath);

  // =========================================================
  // READ OPERATIONS
  // =========================================================

  /// Retrieves all wishlist items for a specific [userId] ordered by creation date descending.
  Future<List<WishlistModel>> getUserWishlist(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'fetching user wishlist');
    } catch (e) {
      throw _handleGenericException(e, 'fetching user wishlist');
    }
  }

  /// Fetches a specific wishlist item document for a given [userId] and [productId].
  Future<WishlistModel?> getWishlistItem(
    String userId,
    String productId,
  ) async {
    _validateNonEmpty(userId, fieldName: 'userId');
    _validateNonEmpty(productId, fieldName: 'productId');

    try {
      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return WishlistModel.fromMap(doc.data(), documentId: doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'fetching wishlist item');
    } catch (e) {
      throw _handleGenericException(e, 'fetching wishlist item');
    }
  }

  /// Checks if a product exists in the user's wishlist.
  Future<bool> isProductInWishlist(String userId, String productId) async {
    return wishlistExists(userId, productId);
  }

  /// Returns the total count of wishlist items for a given [userId].
  /// Uses Firestore aggregation query for optimized read costs.
  Future<int> getWishlistCount(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final countQuery = await _wishlistRef
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return countQuery.count ?? 0;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'fetching wishlist count');
    } catch (e) {
      throw _handleGenericException(e, 'fetching wishlist count');
    }
  }

  // =========================================================
  // STREAM SUPPORT
  // =========================================================

  /// Listens to real-time updates for a user's wishlist items.
  Stream<List<WishlistModel>> watchWishlist(String userId) {
    _validateNonEmpty(userId, fieldName: 'userId');

    return _wishlistRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      if (error is FirebaseException) {
        throw _handleFirebaseException(error, 'watching wishlist stream');
      }
      throw _handleGenericException(error, 'watching wishlist stream');
    });
  }

  // =========================================================
  // VALIDATION HELPERS
  // =========================================================

  /// Checks whether a wishlist document exists for [userId] and [productId].
  Future<bool> wishlistExists(String userId, String productId) async {
    _validateNonEmpty(userId, fieldName: 'userId');
    _validateNonEmpty(productId, fieldName: 'productId');

    try {
      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'checking wishlist existence');
    } catch (e) {
      throw _handleGenericException(e, 'checking wishlist existence');
    }
  }

  // =========================================================
  // CREATE OPERATIONS
  // =========================================================

  /// Adds a new product to the user's wishlist.
  /// Validates user existence, product existence, activity status, and duplicates.
  Future<void> addToWishlist(WishlistModel wishlist) async {
    _validateNonEmpty(wishlist.userId, fieldName: 'userId');
    _validateNonEmpty(wishlist.productId, fieldName: 'productId');

    try {
      // 1. Verify User Exists
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(wishlist.userId)
          .get();

      if (!userDoc.exists) {
        throw const WishlistServiceException(
          'Target user does not exist.',
          code: 'user-not-found',
        );
      }

      // 2. Verify Product Exists and is Active
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(wishlist.productId)
          .get();

      if (!productDoc.exists) {
        throw const WishlistServiceException(
          'Target product does not exist.',
          code: 'product-not-found',
        );
      }

      final productData = productDoc.data();
      final bool isActive = productData?['isActive'] as bool? ?? false;

      if (!isActive) {
        throw const WishlistServiceException(
          'Cannot add an inactive product to wishlist.',
          code: 'product-inactive',
        );
      }

      // 3. Verify Product is NOT already in Wishlist
      final alreadyExists = await wishlistExists(
        wishlist.userId,
        wishlist.productId,
      );

      if (alreadyExists) {
        throw const WishlistServiceException(
          'Product is already in the wishlist.',
          code: 'duplicate-item',
        );
      }

      // 4. Perform Write
      final docRef = wishlist.id.isNotEmpty
          ? _wishlistRef.doc(wishlist.id)
          : _wishlistRef.doc();

      final now = DateTime.now();
      final dataToWrite = wishlist
          .copyWith(
            id: docRef.id,
            createdAt: wishlist.createdAt,
            updatedAt: now,
          )
          .toMap();

      await docRef.set(dataToWrite);
    } on WishlistServiceException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'adding item to wishlist');
    } catch (e) {
      throw _handleGenericException(e, 'adding item to wishlist');
    }
  }

  // =========================================================
  // UPDATE OPERATIONS
  // =========================================================

  /// Updates an existing wishlist item and bumps the `updatedAt` field.
  Future<void> updateWishlistItem(WishlistModel wishlist) async {
    _validateNonEmpty(wishlist.id, fieldName: 'wishlistId');

    try {
      final docRef = _wishlistRef.doc(wishlist.id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw const WishlistServiceException(
          'Wishlist item document not found.',
          code: 'document-not-found',
        );
      }

      final updatedData = wishlist
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toMap();

      await docRef.update(updatedData);
    } on WishlistServiceException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'updating wishlist item');
    } catch (e) {
      throw _handleGenericException(e, 'updating wishlist item');
    }
  }

  // =========================================================
  // DELETE OPERATIONS
  // =========================================================

  /// Removes a wishlist item by its document [wishlistId].
  Future<void> removeFromWishlist(String wishlistId) async {
    _validateNonEmpty(wishlistId, fieldName: 'wishlistId');

    try {
      await _wishlistRef.doc(wishlistId).delete();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'removing item from wishlist');
    } catch (e) {
      throw _handleGenericException(e, 'removing item from wishlist');
    }
  }

  /// Removes a product from a user's wishlist using [userId] and [productId].
  Future<void> removeProductFromWishlist(
    String userId,
    String productId,
  ) async {
    _validateNonEmpty(userId, fieldName: 'userId');
    _validateNonEmpty(productId, fieldName: 'productId');

    try {
      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) {
        throw const WishlistServiceException(
          'Wishlist item not found for removal.',
          code: 'document-not-found',
        );
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on WishlistServiceException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(
        e,
        'removing product from wishlist',
      );
    } catch (e) {
      throw _handleGenericException(
        e,
        'removing product from wishlist',
      );
    }
  }

  /// Clears all wishlist items for a given [userId] using a batched write operation.
  Future<void> clearWishlist(String userId) async {
    _validateNonEmpty(userId, fieldName: 'userId');

    try {
      final snapshot =
          await _wishlistRef.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'clearing user wishlist');
    } catch (e) {
      throw _handleGenericException(e, 'clearing user wishlist');
    }
  }

  // =========================================================
  // PRIVATE EXCEPTION & VALIDATION HELPERS
  // =========================================================

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw WishlistServiceException(
        '$fieldName cannot be empty.',
        code: 'invalid-argument',
      );
    }
  }

  WishlistServiceException _handleFirebaseException(
    FirebaseException e,
    String context,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return WishlistServiceException(
          'Permission denied while $context.',
          code: 'permission-denied',
          details: e.message,
        );
      case 'unavailable':
      case 'network-request-failed':
        return WishlistServiceException(
          'Network connection failure while $context. Please check your internet connection.',
          code: 'network-failure',
          details: e.message,
        );
      case 'unauthenticated':
        return WishlistServiceException(
          'User is unauthenticated. Please log in again.',
          code: 'unauthenticated',
          details: e.message,
        );
      case 'not-found':
        return WishlistServiceException(
          'Requested wishlist document not found.',
          code: 'document-not-found',
          details: e.message,
        );
      case 'already-exists':
        return WishlistServiceException(
          'Wishlist document already exists.',
          code: 'duplicate-item',
          details: e.message,
        );
      default:
        return WishlistServiceException(
          'Firestore operation failed while $context: ${e.message ?? e.code}',
          code: e.code,
          details: e,
        );
    }
  }

  WishlistServiceException _handleGenericException(
    Object error,
    String context,
  ) {
    if (error is WishlistServiceException) return error;

    return WishlistServiceException(
      'An unexpected error occurred while $context.',
      code: 'unknown-error',
      details: error,
    );
  }
}