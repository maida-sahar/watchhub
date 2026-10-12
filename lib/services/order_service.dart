import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

/// Exception wrapper for OrderService failures.
class OrderServiceException implements Exception {
  final String message;
  final String? code;

  const OrderServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

/// A single timestamped entry in an order's status history, stored in
/// the `orders/{orderId}/statusHistory` subcollection. Kept as a small
/// companion class here (rather than a new file, and rather than
/// touching `OrderModel`, which this task doesn't authorize modifying)
/// since it's purely an admin/audit concern layered on top of the
/// existing order schema.
class OrderStatusHistoryEntry {
  final String status;
  final DateTime changedAt;

  const OrderStatusHistoryEntry({
    required this.status,
    required this.changedAt,
  });

  factory OrderStatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['changedAt'];
    final changedAt = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.now();
    return OrderStatusHistoryEntry(
      status: map['status'] as String? ?? '',
      changedAt: changedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'changedAt': Timestamp.fromDate(changedAt),
    };
  }
}

/// Service that interacts directly with Firestore for User Orders.
class OrderService {
  final FirebaseFirestore _firestore;

  static const String _ordersCollection = 'orders';
  static const String _productsCollection = 'products';
  static const String _statusHistorySubcollection = 'statusHistory';

  /// Canonical forward progression of an order's lifecycle, lowercase
  /// to match how `orderStatus` is already stored (see
  /// `OrderModel.fromMap` / `cancelOrder`'s existing lowercase
  /// comparisons). 'cancelled' is deliberately NOT part of this
  /// sequence — it's a separate terminal branch reachable from any
  /// non-terminal status via [cancelOrder], not via [updateOrderStatus].
  static const List<String> statusSequence = [
    'pending',
    'confirmed',
    'processing',
    'packed',
    'shipped',
    'out for delivery',
    'delivered',
  ];

  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection(_ordersCollection);

  CollectionReference<Map<String, dynamic>> _statusHistoryRef(String orderId) =>
      _ordersRef.doc(orderId).collection(_statusHistorySubcollection);

  /// Streams list of all orders for a specific user, sorted by creation date descending.
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value([]);
    }
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<OrderModel> orders = [];
      for (final doc in snapshot.docs) {
        try {
          orders.add(OrderModel.fromMap(doc.data(), documentId: doc.id));
        } catch (_) {
          // Log or skip malformed document in production
        }
      }
      // Sort in-memory just in case, or rely on Firestore indexes.
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Streams a single order by its ID to listen to real-time changes.
  Stream<OrderModel?> watchOrderById(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _ordersRef.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      try {
        return OrderModel.fromMap(snapshot.data()!, documentId: snapshot.id);
      } catch (e) {
        throw OrderServiceException('Malformed order data: $e');
      }
    });
  }

  /// Transactionally cancels an order, restoring product stock in the database.
  Future<void> cancelOrder(String orderId, String reason) async {
    if (orderId.trim().isEmpty) {
      throw const OrderServiceException('Order ID is required to cancel an order.');
    }
    if (reason.trim().isEmpty) {
      throw const OrderServiceException('Cancellation reason is required.');
    }

    try {
      final orderDocRef = _ordersRef.doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderDocRef);
        if (!orderSnapshot.exists || orderSnapshot.data() == null) {
          throw const OrderServiceException('Order document does not exist.');
        }

        final order = OrderModel.fromMap(orderSnapshot.data()!, documentId: orderSnapshot.id);

        // Check validation status: only pending, confirmed, processing can be cancelled
        final currentStatus = order.orderStatus.toLowerCase();
        if (currentStatus == 'cancelled') {
          throw const OrderServiceException('This order has already been cancelled.');
        }
        if (currentStatus == 'shipped' ||
            currentStatus == 'out for delivery' ||
            currentStatus == 'delivered') {
          throw OrderServiceException(
            'Cannot cancel order at this stage. Current status is: ${order.orderStatus}.',
          );
        }
        if (currentStatus != 'pending' &&
            currentStatus != 'confirmed' &&
            currentStatus != 'processing') {
          throw OrderServiceException('Invalid order status: ${order.orderStatus}.');
        }

        // Restore inventory stock for all products in the order
        for (final item in order.items) {
          final productRef = _firestore.collection(_productsCollection).doc(item.productId);
          final productSnapshot = await transaction.get(productRef);

          if (productSnapshot.exists && productSnapshot.data() != null) {
            final data = productSnapshot.data()!;
            final currentStock = (data['stock'] as num?)?.toInt() ?? 0;

            transaction.update(productRef, {
              'stock': currentStock + item.quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update the order details
        transaction.update(orderDocRef, {
          'orderStatus': 'cancelled',
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw OrderServiceException(e.message ?? 'Firestore transaction failed.', code: e.code);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException('An unexpected error occurred while cancelling order: $e');
    }
  }

  // =========================================================
  // ADMIN — Orders List, Status Management, Status History
  // =========================================================

  /// Streams every order in the system, sorted by creation date
  /// descending, for the Admin Orders list. Unlike [watchUserOrders],
  /// this is intentionally unscoped — Firestore security rules are
  /// responsible for ensuring only an admin account can read this.
  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersRef.snapshots().map((snapshot) {
      final List<OrderModel> orders = [];
      for (final doc in snapshot.docs) {
        try {
          orders.add(OrderModel.fromMap(doc.data(), documentId: doc.id));
        } catch (_) {
          // Skip malformed document rather than crash the whole list.
        }
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Updates an order's status as part of the admin fulfillment flow,
  /// enforcing that status can only move forward through
  /// [statusSequence] and never out of a terminal state.
  ///
  /// This method does NOT handle cancellation — [cancelOrder] already
  /// owns that path (including restoring product stock transactionally)
  /// and stays the single source of truth for it, so admins cancelling
  /// an order should call [cancelOrder] instead of this method.
  ///
  /// On success, also appends a timestamped entry to
  /// `orders/{orderId}/statusHistory`, since [OrderModel] itself has no
  /// history field.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (orderId.trim().isEmpty) {
      throw const OrderServiceException('Order ID is required to update status.');
    }

    final normalizedNewStatus = newStatus.trim().toLowerCase();
    if (normalizedNewStatus == 'cancelled') {
      throw const OrderServiceException(
        'Use cancelOrder() to cancel an order, not updateOrderStatus().',
      );
    }
    if (!statusSequence.contains(normalizedNewStatus)) {
      throw OrderServiceException('Unknown order status: "$newStatus".');
    }

    final orderDocRef = _ordersRef.doc(orderId);

    try {
      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderDocRef);
        if (!orderSnapshot.exists || orderSnapshot.data() == null) {
          throw const OrderServiceException('Order document does not exist.');
        }

        final order = OrderModel.fromMap(orderSnapshot.data()!, documentId: orderSnapshot.id);
        final currentStatus = order.orderStatus.trim().toLowerCase();

        if (currentStatus == 'cancelled' || currentStatus == 'delivered') {
          throw OrderServiceException(
            'Cannot change status: order is already "${order.orderStatus}".',
          );
        }

        final currentIndex = statusSequence.indexOf(currentStatus);
        final newIndex = statusSequence.indexOf(normalizedNewStatus);

        if (currentIndex == -1) {
          throw OrderServiceException(
            'Current order status "${order.orderStatus}" is not recognized.',
          );
        }
        if (newIndex <= currentIndex) {
          throw OrderServiceException(
            'Invalid status change: cannot move from "${order.orderStatus}" to "$newStatus".',
          );
        }

        transaction.update(orderDocRef, {
          'orderStatus': normalizedNewStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Status history is appended in the same transaction so the
        // order document and its audit trail never drift out of sync.
        transaction.set(_statusHistoryRef(orderId).doc(), {
          'status': normalizedNewStatus,
          'changedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw OrderServiceException(e.message ?? 'Firestore transaction failed.', code: e.code);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException('An unexpected error occurred while updating order status: $e');
    }
  }

  /// Streams an order's status history, oldest first, so a timeline
  /// widget can render it top-to-bottom in chronological order.
  Stream<List<OrderStatusHistoryEntry>> watchOrderStatusHistory(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream.value([]);
    }
    return _statusHistoryRef(orderId)
        .orderBy('changedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderStatusHistoryEntry.fromMap(doc.data()))
            .toList());
  }
}