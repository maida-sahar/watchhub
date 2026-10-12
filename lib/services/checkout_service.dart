import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/checkout_model.dart';
import '../models/order_model.dart';

/// Exception wrapper for CheckoutService failures.
class CheckoutServiceException implements Exception {
  final String message;
  final String? code;

  const CheckoutServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service that interacts directly with Firestore for Checkout and Address operations.
class CheckoutService {
  final FirebaseFirestore _firestore;

  static const String _addressesCollection = 'addresses';

  CheckoutService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _addressesRef =>
      _firestore.collection(_addressesCollection);

  // =========================================================
  // ADDRESS CRUD OPERATIONS
  // =========================================================

  /// Retrieves a real-time stream of all shipping addresses for a specific user.
  Stream<List<ShippingAddress>> watchAddresses(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value([]);
    }
    return _addressesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final addresses = snapshot.docs
          .map((doc) => ShippingAddress.fromMap(doc.data(), documentId: doc.id))
          .toList();
      // Sort: defaults first, then by createdAt descending
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return addresses;
    });
  }

  /// Retrieves all user addresses as a future list.
  Future<List<ShippingAddress>> getUserAddresses(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      final snapshot = await _addressesRef
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs
          .map((doc) => ShippingAddress.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to fetch user addresses.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('An unexpected error occurred while fetching addresses: $e');
    }
  }

  /// Retrieves the current default shipping address of the user.
  Future<ShippingAddress?> getDefaultAddress(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      final snapshot = await _addressesRef
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ShippingAddress.fromMap(snapshot.docs.first.data(), documentId: snapshot.docs.first.id);
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to fetch default address.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('An unexpected error occurred: $e');
    }
  }

  /// Saves a new address. Enforces the business rules for default statuses.
  Future<ShippingAddress> saveAddress(ShippingAddress address) async {
    if (address.userId.isEmpty) {
      throw const CheckoutServiceException('User ID cannot be empty when saving an address.');
    }

    try {
      final existingAddresses = await getUserAddresses(address.userId);
      final isFirstAddress = existingAddresses.isEmpty;
      
      // Enforce: first address must always be default
      final shouldBeDefault = isFirstAddress || address.isDefault;
      
      final docRef = _addressesRef.doc();
      final finalAddress = address.copyWith(
        id: docRef.id,
        isDefault: shouldBeDefault,
      );

      final batch = _firestore.batch();
      
      // If setting as default, unmark other addresses
      if (shouldBeDefault) {
        for (final oldAddress in existingAddresses) {
          if (oldAddress.isDefault) {
            batch.update(_addressesRef.doc(oldAddress.id), {'isDefault': false, 'updatedAt': FieldValue.serverTimestamp()});
          }
        }
      }

      batch.set(docRef, finalAddress.toMap());
      await batch.commit();

      return finalAddress;
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to save address.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('Failed to save address: $e');
    }
  }

  /// Updates an existing address.
  Future<void> updateAddress(ShippingAddress address) async {
    if (address.id.isEmpty || address.userId.isEmpty) {
      throw const CheckoutServiceException('Address and User ID cannot be empty.');
    }

    try {
      final existingAddresses = await getUserAddresses(address.userId);
      
      // If this address is the only one, it must remain default
      final isOnlyAddress = existingAddresses.length == 1 && existingAddresses.first.id == address.id;
      final shouldBeDefault = isOnlyAddress || address.isDefault;

      final updatedAddress = address.copyWith(
        isDefault: shouldBeDefault,
        updatedAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      if (shouldBeDefault) {
        for (final oldAddress in existingAddresses) {
          if (oldAddress.id != address.id && oldAddress.isDefault) {
            batch.update(_addressesRef.doc(oldAddress.id), {'isDefault': false, 'updatedAt': FieldValue.serverTimestamp()});
          }
        }
      } else {
        // If we are unmarking this address as default, make sure another one becomes default
        final wasDefault = existingAddresses.any((a) => a.id == address.id && a.isDefault);
        if (wasDefault) {
          final nextDefault = existingAddresses.firstWhere((a) => a.id != address.id, orElse: () => address);
          if (nextDefault.id != address.id) {
            batch.update(_addressesRef.doc(nextDefault.id), {'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()});
          }
        }
      }

      batch.update(_addressesRef.doc(address.id), updatedAddress.toMap());
      await batch.commit();
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to update address.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('Failed to update address: $e');
    }
  }

  /// Deletes an address. Handles default re-assignment logic if necessary.
  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      throw const CheckoutServiceException('User ID and Address ID are required for deletion.');
    }

    try {
      final existingAddresses = await getUserAddresses(userId);
      final targetAddress = existingAddresses.firstWhere(
        (a) => a.id == addressId,
        orElse: () => throw const CheckoutServiceException('Address to delete not found.'),
      );

      final batch = _firestore.batch();
      batch.delete(_addressesRef.doc(addressId));

      // If we are deleting the default address, make the next available one default
      if (targetAddress.isDefault && existingAddresses.length > 1) {
        final nextDefault = existingAddresses.firstWhere((a) => a.id != addressId);
        batch.update(_addressesRef.doc(nextDefault.id), {'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to delete address.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('Failed to delete address: $e');
    }
  }

  /// Sets a specific address as default for a user, resetting all others.
  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      throw const CheckoutServiceException('User ID and Address ID are required.');
    }

    try {
      final existingAddresses = await getUserAddresses(userId);
      final batch = _firestore.batch();

      for (final address in existingAddresses) {
        if (address.id == addressId) {
          batch.update(_addressesRef.doc(address.id), {'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()});
        } else if (address.isDefault) {
          batch.update(_addressesRef.doc(address.id), {'isDefault': false, 'updatedAt': FieldValue.serverTimestamp()});
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Failed to set default address.', code: e.code);
    } catch (e) {
      throw CheckoutServiceException('Failed to set default address: $e');
    }
  }

  // =========================================================
  // CHECKOUT VALIDATION & PREPARATION
  // =========================================================

  /// Validates checkout criteria against real-time database state.
  Future<void> validateCheckout({
    required String userId,
    required String? addressId,
    required List<CartModel> cartItems,
    DeliveryMethod? deliveryMethod,
  }) async {
    if (userId.trim().isEmpty) {
      throw const CheckoutServiceException('User must be logged in to checkout.');
    }
    if (cartItems.isEmpty) {
      throw const CheckoutServiceException('Your cart is empty.');
    }
    if (addressId == null || addressId.trim().isEmpty) {
      throw const CheckoutServiceException('Please select a shipping address.');
    }

    // 1. Verify address exists and is valid
    final addressDoc = await _addressesRef.doc(addressId).get();
    if (!addressDoc.exists || addressDoc.data() == null) {
      throw const CheckoutServiceException('Selected shipping address does not exist.');
    }
    final address = ShippingAddress.fromMap(addressDoc.data()!, documentId: addressDoc.id);
    if (address.userId != userId) {
      throw const CheckoutServiceException('Address validation failed: address does not belong to user.');
    }
    if (address.fullName.trim().isEmpty ||
        address.phone.trim().isEmpty ||
        address.country.trim().isEmpty ||
        address.province.trim().isEmpty ||
        address.city.trim().isEmpty ||
        address.area.trim().isEmpty ||
        address.streetAddress.trim().isEmpty ||
        address.postalCode.trim().isEmpty) {
      throw const CheckoutServiceException('Please fill in all required fields in the shipping address.');
    }

    // 2. Validate product availability and stock
    for (final item in cartItems) {
      final productDoc = await _firestore.collection('products').doc(item.productId).get();
      if (!productDoc.exists) {
        throw CheckoutServiceException('Product "${item.productName}" no longer exists.');
      }
      final data = productDoc.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final stock = (data['stock'] as num?)?.toInt() ?? 0;

      if (!isActive) {
        throw CheckoutServiceException('Product "${item.productName}" is no longer active.');
      }
      if (stock < item.quantity) {
        throw CheckoutServiceException(
            'Product "${item.productName}" has insufficient stock. Available: $stock, Requested: ${item.quantity}.');
      }
    }
  }

  /// Calculates totals and constructs the CheckoutModel structure.
  CheckoutModel prepareCheckout({
    required String userId,
    required List<CartModel> cartItems,
    required ShippingAddress? shippingAddress,
    DeliveryMethod? deliveryMethod,
    double taxRate = 0.0,
    double defaultDeliveryCharge = 5.0,
  }) {
    final subtotal = cartItems.fold<double>(0.0, (total, item) => total + (item.price * item.quantity));
    final grandTotalFromCart = cartItems.fold<double>(0.0, (total, item) => total + (item.discountPrice * item.quantity));
    final discount = subtotal - grandTotalFromCart;
    final finalDiscount = discount < 0.0 ? 0.0 : discount;

    final shippingCharge = deliveryMethod?.id == 'store_pickup'
        ? 0.0
        : (deliveryMethod?.deliveryCharge ?? defaultDeliveryCharge);
    const double couponDiscount = 0.0;
    
    final tax = (grandTotalFromCart + shippingCharge) * (taxRate / 100);
    final grandTotal = grandTotalFromCart + shippingCharge + tax - couponDiscount;

    final now = DateTime.now();
    return CheckoutModel(
      id: '',
      userId: userId,
      cartItems: cartItems,
      shippingAddress: shippingAddress,
      deliveryMethod: deliveryMethod,
      subtotal: subtotal,
      discount: finalDiscount,
      couponDiscount: couponDiscount,
      shippingCharge: shippingCharge,
      tax: tax,
      grandTotal: grandTotal < 0.0 ? 0.0 : grandTotal,
      currency: 'USD',
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );
  }

  // =========================================================
  // PLACE ORDER TRANSACTION
  // =========================================================

  /// Transactional order placement workflow. Decrements product stocks and clears user cart.
  Future<String> placeOrder(OrderModel order) async {
    if (order.userId.isEmpty) {
      throw const CheckoutServiceException('User ID is required to place an order.');
    }

    try {
      // 1. Query user's cart documents to delete them later
      final cartSnapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: order.userId)
          .get();

      final orderDocRef = _firestore.collection('orders').doc();

      // 2. Perform transactional verification and modifications
      await _firestore.runTransaction((transaction) async {
        for (final item in order.items) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);

          if (!productDoc.exists) {
            throw CheckoutServiceException('Product "${item.productName}" no longer exists.');
          }

          final data = productDoc.data()!;
          final isActive = data['isActive'] as bool? ?? false;
          final stock = (data['stock'] as num?)?.toInt() ?? 0;

          if (!isActive) {
            throw CheckoutServiceException('Product "${item.productName}" is no longer active and cannot be purchased.');
          }
          if (stock < item.quantity) {
            throw CheckoutServiceException('Insufficient stock for "${item.productName}". Available: $stock, Requested: ${item.quantity}.');
          }

          // Decrement product inventory stock
          transaction.update(productRef, {
            'stock': stock - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Save order document
        final finalOrder = order.copyWith(orderId: orderDocRef.id);
        transaction.set(orderDocRef, finalOrder.toMap());

        // Clear user's shopping cart items
        for (final doc in cartSnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });

      return orderDocRef.id;
    } on FirebaseException catch (e) {
      throw CheckoutServiceException(e.message ?? 'Firestore transaction failed.', code: e.code);
    } catch (e) {
      if (e is CheckoutServiceException) rethrow;
      throw CheckoutServiceException('Failed to place order: $e');
    }
  }
}
