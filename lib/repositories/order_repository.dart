import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/order_service.dart';

/// Exception specific to high-level order repository operations.
class OrderException implements Exception {
  final String message;
  const OrderException(this.message);

  @override
  String toString() => message;
}

/// Order repository to handle order queries, real-time updates, and cancellations.
class OrderRepository {
  final OrderService _service;
  final FirestoreService _firestoreService;

  // ignore: prefer_initializing_formals
  OrderRepository({
    required OrderService service,
    required FirestoreService firestoreService,
  })  : _service = service,
        _firestoreService = firestoreService;

  /// Exposes a real-time stream of the user's orders list.
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _service.watchUserOrders(userId);
  }

  /// Exposes a real-time stream of a specific order by ID.
  Stream<OrderModel?> watchOrderById(String orderId) {
    return _service.watchOrderById(orderId);
  }

  /// Cancels an order and restores product stocks in database.
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _service.cancelOrder(orderId, reason);
    } catch (e) {
      throw OrderException(e.toString());
    }
  }

  // =========================================================
  // ADMIN — Orders List, Status Management, Customer Lookup
  // =========================================================

  /// Streams every order in the system for the Admin Orders list.
  Stream<List<OrderModel>> watchAllOrders() {
    return _service.watchAllOrders();
  }

  /// Updates an order's status (forward-only, non-terminal states only
  /// — see [OrderService.updateOrderStatus] for the enforced rules).
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _service.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      throw OrderException(e.toString());
    }
  }

  /// Streams an order's timestamped status history for the Admin
  /// Order Details timeline.
  Stream<List<OrderStatusHistoryEntry>> watchOrderStatusHistory(String orderId) {
    return _service.watchOrderStatusHistory(orderId);
  }

  /// Fetches the customer profile behind an order's `userId`, for the
  /// Admin Order Details screen's customer info card.
  ///
  /// This composes [FirestoreService] (the app's single owner of
  /// `users` collection reads/writes) rather than the repository
  /// reaching into Firestore itself — the Order module gains read
  /// access to user profiles without any UI layer bypassing Provider,
  /// and without `OrderService` taking on a responsibility (`users`
  /// collection access) that belongs to a different domain.
  Future<UserModel?> getCustomerInfo(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      return await _firestoreService.getUserDocument(userId);
    } catch (e) {
      throw OrderException('Failed to load customer info: $e');
    }
  }

  /// Streams the customer profile behind an order's `userId`, so the
  /// Customer Order Details screen can reflect profile edits (name,
  /// phone, etc.) in real time without a manual refresh. Reuses
  /// [FirestoreService.watchUserDocument] — the same single owner of
  /// `users` collection access used by [getCustomerInfo] above.
  Stream<UserModel?> watchCustomerProfile(String userId) {
    if (userId.trim().isEmpty) return Stream.value(null);
    return _firestoreService.watchUserDocument(userId);
  }

  /// Fetches customer profiles for a set of user ids in parallel, for
  /// the Sales Report's "Top Customers" section. Composes
  /// [FirestoreService]'s existing single-user fetch rather than
  /// adding a new batch method there, since order volumes in this app
  /// don't warrant a `whereIn` query (which would also cap out at 30
  /// ids per call and need chunking).
  ///
  /// Ids that fail to resolve (deleted user, transient error) are
  /// simply omitted from the result map rather than failing the whole
  /// batch — a missing customer profile shouldn't block the report.
  Future<Map<String, UserModel>> getCustomerProfilesByIds(Set<String> userIds) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) return {};

    final entries = await Future.wait(
      ids.map((id) async {
        try {
          final profile = await _firestoreService.getUserDocument(id);
          return MapEntry(id, profile);
        } catch (_) {
          return MapEntry(id, null);
        }
      }),
    );

    final result = <String, UserModel>{};
    for (final entry in entries) {
      final profile = entry.value;
      if (profile != null) result[entry.key] = profile;
    }
    return result;
  }
}