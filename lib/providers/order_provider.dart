import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../repositories/order_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/order_service.dart' show OrderStatusHistoryEntry;

/// Provider for managing customer order states, real-time sync, and cancellations.
class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;

  /// Optional — when supplied, [updateOrderStatus] automatically sends the
  /// customer a notification ("Your order has been shipped.", etc.),
  /// closing the gap where order-status pushes previously required an
  /// admin to create them by hand. Nullable/optional so this provider still
  /// works in any test/context that doesn't wire notifications.
  final NotificationRepository? _notificationRepository;

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<OrderModel?>? _currentOrderSubscription;

  String? _watchedUserId;
  String? _watchedOrderId;

  // --- Admin: all-orders list ---------------------------------
  List<OrderModel> _allOrders = [];
  bool _isLoadingAllOrders = false;
  String? _allOrdersError;
  StreamSubscription<List<OrderModel>>? _allOrdersSubscription;
  bool _isWatchingAllOrders = false;

  // --- Admin: customer profiles cache, keyed by userId ------------
  // Populated incrementally as new userIds appear in _allOrders, so
  // the Sales Report's Top Customers section can resolve a name for
  // each customer without a per-row Firestore read.
  final Map<String, UserModel> _customerProfilesByUserId = {};

  // --- Admin: status update ------------------------------------
  bool _isUpdatingStatus = false;
  String? _statusUpdateError;

  // --- Admin: status history timeline ---------------------------
  List<OrderStatusHistoryEntry> _statusHistory = [];
  StreamSubscription<List<OrderStatusHistoryEntry>>? _statusHistorySubscription;
  String? _watchedHistoryOrderId;

  // --- Admin: customer info lookup (one-shot) --------------------
  UserModel? _customerInfo;
  bool _isLoadingCustomerInfo = false;
  String? _customerInfoError;

  // --- Admin: Customer Order Details screen -----------------------
  // Kept separate from _orders/_watchedUserId above (which back the
  // CUSTOMER's own "My Orders" screen) so an admin viewing a
  // customer's profile never collides with a customer's own order
  // list state if both happen to be active in the same app instance.
  UserModel? _customerProfile;
  bool _isLoadingCustomerProfile = false;
  String? _customerProfileError;
  StreamSubscription<UserModel?>? _customerProfileSubscription;
  String? _watchedCustomerProfileId;

  List<OrderModel> _customerOrderHistory = [];
  bool _isLoadingCustomerOrderHistory = false;
  String? _customerOrderHistoryError;
  StreamSubscription<List<OrderModel>>? _customerOrderHistorySubscription;
  String? _watchedCustomerOrderHistoryId;

  // ignore: prefer_initializing_formals
  OrderProvider({required OrderRepository repository, NotificationRepository? notificationRepository})
      : _repository = repository,
        _notificationRepository = notificationRepository;

  List<OrderModel> get orders => _orders;

  /// True if the currently-watched user has at least one non-cancelled
  /// order containing [productId] — used to gate "Write a Review" to
  /// customers who actually bought the product (per PRD: review after
  /// purchase). Reads from the already-loaded [orders] list rather than
  /// issuing a new Firestore query.
  bool hasPurchased(String productId) {
    return _orders.any((order) =>
        order.orderStatus.toLowerCase() != 'cancelled' &&
        order.items.any((item) => item.productId == productId));
  }
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> get allOrders => List.unmodifiable(_allOrders);
  bool get isLoadingAllOrders => _isLoadingAllOrders;
  String? get allOrdersError => _allOrdersError;

  Map<String, UserModel> get customerProfilesByUserId =>
      Map.unmodifiable(_customerProfilesByUserId);

  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get statusUpdateError => _statusUpdateError;

  List<OrderStatusHistoryEntry> get statusHistory => List.unmodifiable(_statusHistory);

  UserModel? get customerInfo => _customerInfo;
  bool get isLoadingCustomerInfo => _isLoadingCustomerInfo;
  String? get customerInfoError => _customerInfoError;

  UserModel? get customerProfile => _customerProfile;
  bool get isLoadingCustomerProfile => _isLoadingCustomerProfile;
  String? get customerProfileError => _customerProfileError;

  List<OrderModel> get customerOrderHistory => List.unmodifiable(_customerOrderHistory);
  bool get isLoadingCustomerOrderHistory => _isLoadingCustomerOrderHistory;
  String? get customerOrderHistoryError => _customerOrderHistoryError;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Listens to real-time updates for a user's orders.
  /// Skips duplicate calls for the same userId to optimize Firestore reads and rebuilds.
  void watchUserOrders(String userId) {
    if (userId.trim().isEmpty) {
      _orders = [];
      _watchedUserId = null;
      _ordersSubscription?.cancel();
      _ordersSubscription = null;
      notifyListeners();
      return;
    }

    if (_watchedUserId == userId && _ordersSubscription != null) {
      return; // Already listening to this user's orders
    }

    _watchedUserId = userId;
    _ordersSubscription?.cancel();
    
    _setLoading(true);
    _ordersSubscription = _repository.watchUserOrders(userId).listen(
      (updatedOrders) {
        _orders = updatedOrders;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load orders: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Listens to real-time updates for a single order details.
  /// Skips duplicate calls for the same orderId to optimize streams.
  void watchOrderById(String orderId) {
    if (orderId.trim().isEmpty) {
      _currentOrder = null;
      _watchedOrderId = null;
      _currentOrderSubscription?.cancel();
      _currentOrderSubscription = null;
      notifyListeners();
      return;
    }

    if (_watchedOrderId == orderId && _currentOrderSubscription != null) {
      return; // Already listening to this order
    }

    _watchedOrderId = orderId;
    _currentOrderSubscription?.cancel();
    _currentOrder = null; // Clear previous state to avoid UI flashes
    
    _currentOrderSubscription = _repository.watchOrderById(orderId).listen(
      (order) {
        _currentOrder = order;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load order details: $error';
        notifyListeners();
      },
    );
  }

  /// Stops listening to a single order and clears the cached current order.
  void clearCurrentOrder() {
    _watchedOrderId = null;
    _currentOrderSubscription?.cancel();
    _currentOrderSubscription = null;
    _currentOrder = null;
  }

  /// Cancels an order. Returns true if cancellation succeeded.
  Future<bool> cancelOrder(String orderId, String reason) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.cancelOrder(orderId, reason);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _setError(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _currentOrderSubscription?.cancel();
    _allOrdersSubscription?.cancel();
    _statusHistorySubscription?.cancel();
    _customerProfileSubscription?.cancel();
    _customerOrderHistorySubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // ADMIN — Orders List
  // =========================================================

  /// Subscribes to a real-time stream of every order in the system, for
  /// the Admin Orders list. Skips re-subscribing if already watching,
  /// matching the guard pattern used by [watchUserOrders]/
  /// [watchOrderById] above.
  void watchAllOrders() {
    if (_isWatchingAllOrders && _allOrdersSubscription != null) return;

    _isWatchingAllOrders = true;
    _isLoadingAllOrders = true;
    _allOrdersError = null;
    notifyListeners();

    _allOrdersSubscription?.cancel();
    _allOrdersSubscription = _repository.watchAllOrders().listen(
      (updatedOrders) {
        _allOrders = updatedOrders;
        _allOrdersError = null;
        _isLoadingAllOrders = false;
        notifyListeners();
        _fetchMissingCustomerProfiles(updatedOrders);
      },
      onError: (error) {
        _allOrdersError = 'Failed to load orders: $error';
        _isLoadingAllOrders = false;
        _isWatchingAllOrders = false;
        notifyListeners();
      },
    );
  }

  /// Fetches customer profiles for any userIds in [orders] not already
  /// cached in [_customerProfilesByUserId]. Runs after each
  /// `watchAllOrders()` emission rather than blocking it, so the orders
  /// list/reports themselves never wait on customer-profile lookups.
  Future<void> _fetchMissingCustomerProfiles(List<OrderModel> orders) async {
    final missingIds = orders
        .map((o) => o.userId)
        .where((id) => id.trim().isNotEmpty && !_customerProfilesByUserId.containsKey(id))
        .toSet();
    if (missingIds.isEmpty) return;

    try {
      final fetched = await _repository.getCustomerProfilesByIds(missingIds);
      if (fetched.isEmpty) return;
      _customerProfilesByUserId.addAll(fetched);
      notifyListeners();
    } catch (_) {
      // Customer profile enrichment is best-effort for report display —
      // a failure here shouldn't surface as a blocking error elsewhere.
    }
  }

  /// Stops watching all orders (e.g. when leaving the Admin Orders
  /// screen), so the subscription doesn't keep running unnecessarily.
  void stopWatchingAllOrders() {
    _isWatchingAllOrders = false;
    _allOrdersSubscription?.cancel();
    _allOrdersSubscription = null;
  }

  // =========================================================
  // ADMIN — Status Management
  // =========================================================

  /// Updates an order's status as part of the admin fulfillment flow.
  /// Returns `true` on success, `false` on failure (with
  /// [statusUpdateError] populated). Never throws — mirrors the bool +
  /// error-message convention used elsewhere in this class
  /// ([cancelOrder]) so calling UI can react without its own try/catch.
  ///
  /// Note: to cancel an order, call [cancelOrder] instead — status
  /// history and stock-restoration logic for cancellation are owned
  /// entirely by that existing method.
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _isUpdatingStatus = true;
    _statusUpdateError = null;
    notifyListeners();

    try {
      await _repository.updateOrderStatus(orderId, newStatus);
      _isUpdatingStatus = false;
      notifyListeners();
      unawaited(_notifyCustomerOfStatusChange(orderId, newStatus));
      return true;
    } catch (e) {
      _isUpdatingStatus = false;
      _statusUpdateError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Order-status notification copy, per PRD §8 ("Order Confirmed",
  /// "Order Shipped", "Order Delivered"). Statuses not listed here (e.g.
  /// 'processing', 'packed') simply don't trigger a push — only the
  /// PRD-specified milestones do.
  static const Map<String, String> _statusNotificationCopy = {
    'confirmed': 'Your order has been confirmed.',
    'shipped': 'Your order has been shipped.',
    'delivered': 'Your order has been delivered.',
  };

  /// Best-effort: looks up the order's owner from the already-loaded order
  /// lists and sends a targeted notification. Never throws — a failure
  /// here must not be mistaken for the status-update itself having failed
  /// (which has already succeeded by the time this runs).
  Future<void> _notifyCustomerOfStatusChange(String orderId, String newStatus) async {
    if (_notificationRepository == null) return;
    final copy = _statusNotificationCopy[newStatus.trim().toLowerCase()];
    if (copy == null) return;

    final order = _findOrderById(orderId);
    if (order == null || order.userId.isEmpty) return;

    try {
      final now = DateTime.now();
      await _notificationRepository!.createNotification(NotificationModel(
        id: '',
        title: 'Order #${order.orderId}',
        body: copy,
        type: 'order',
        recipientType: 'users',
        recipientIds: [order.userId],
        readBy: const [],
        deletedBy: const [],
        createdAt: now,
        updatedAt: now,
      ));
    } catch (_) {
      // Silently skip — order status update has already succeeded and
      // been shown to the admin; a notification-delivery failure shouldn't
      // surface as an order-management error.
    }
  }

  OrderModel? _findOrderById(String orderId) {
    for (final order in _orders) {
      if (order.orderId == orderId) return order;
    }
    for (final order in _allOrders) {
      if (order.orderId == orderId) return order;
    }
    if (_currentOrder?.orderId == orderId) return _currentOrder;
    return null;
  }

  /// Clears the current status-update error, if any.
  void clearStatusUpdateError() {
    if (_statusUpdateError == null) return;
    _statusUpdateError = null;
    notifyListeners();
  }

  // =========================================================
  // ADMIN — Status History Timeline
  // =========================================================

  /// Subscribes to a real-time stream of an order's status history, for
  /// the Admin Order Details timeline. Skips re-subscribing to the same
  /// order, matching the guard pattern used elsewhere in this class.
  void watchOrderStatusHistory(String orderId) {
    if (orderId.trim().isEmpty) {
      _statusHistory = [];
      _watchedHistoryOrderId = null;
      _statusHistorySubscription?.cancel();
      _statusHistorySubscription = null;
      notifyListeners();
      return;
    }

    if (_watchedHistoryOrderId == orderId && _statusHistorySubscription != null) {
      return;
    }

    _watchedHistoryOrderId = orderId;
    _statusHistorySubscription?.cancel();
    _statusHistorySubscription = _repository.watchOrderStatusHistory(orderId).listen(
      (history) {
        _statusHistory = history;
        notifyListeners();
      },
      onError: (_) {
        // Status history is a supplementary/audit view — a failure here
        // shouldn't block the rest of the Order Details screen, so it's
        // swallowed rather than surfaced as a blocking error.
        _statusHistory = [];
        notifyListeners();
      },
    );
  }

  /// Stops watching status history (e.g. when leaving Order Details).
  void clearStatusHistory() {
    _watchedHistoryOrderId = null;
    _statusHistorySubscription?.cancel();
    _statusHistorySubscription = null;
    _statusHistory = [];
  }

  // =========================================================
  // ADMIN — Customer Info Lookup
  // =========================================================

  /// Loads the customer profile behind an order's `userId`, for the
  /// Admin Order Details screen's customer info card. One-shot (not a
  /// stream) since a customer's profile isn't expected to change while
  /// an admin is viewing a single order.
  Future<void> loadCustomerInfo(String userId) async {
    _isLoadingCustomerInfo = true;
    _customerInfoError = null;
    notifyListeners();

    try {
      _customerInfo = await _repository.getCustomerInfo(userId);
      _isLoadingCustomerInfo = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCustomerInfo = false;
      _customerInfoError = 'Failed to load customer info: $e';
      notifyListeners();
    }
  }

  // =========================================================
  // ADMIN — Customer Order Details Screen
  // =========================================================

  /// Subscribes to a real-time stream of a customer's profile, for the
  /// Customer Order Details screen. Skips re-subscribing to the same
  /// customer, matching the guard pattern used elsewhere in this class.
  void watchCustomerProfile(String userId) {
    if (userId.trim().isEmpty) {
      _customerProfile = null;
      _watchedCustomerProfileId = null;
      _customerProfileSubscription?.cancel();
      _customerProfileSubscription = null;
      notifyListeners();
      return;
    }

    if (_watchedCustomerProfileId == userId && _customerProfileSubscription != null) {
      return;
    }

    _watchedCustomerProfileId = userId;
    _customerProfileSubscription?.cancel();
    _isLoadingCustomerProfile = true;
    _customerProfileError = null;
    notifyListeners();

    _customerProfileSubscription = _repository.watchCustomerProfile(userId).listen(
      (profile) {
        _customerProfile = profile;
        _isLoadingCustomerProfile = false;
        _customerProfileError = profile == null ? 'Customer profile not found.' : null;
        notifyListeners();
      },
      onError: (error) {
        _isLoadingCustomerProfile = false;
        _customerProfileError = 'Failed to load customer profile: $error';
        notifyListeners();
      },
    );
  }

  /// Stops watching the customer profile (e.g. when leaving Customer
  /// Order Details).
  void clearCustomerProfile() {
    _watchedCustomerProfileId = null;
    _customerProfileSubscription?.cancel();
    _customerProfileSubscription = null;
    _customerProfile = null;
  }

  /// Subscribes to a real-time stream of a customer's full order
  /// history, for the Customer Order Details screen's order history
  /// list and statistics. Kept separate from [watchUserOrders]/[orders]
  /// above (which back the customer's own "My Orders" screen) even
  /// though both ultimately call the same
  /// `OrderRepository.watchUserOrders`, so an admin viewing someone
  /// else's history never overwrites a customer's own order list state.
  void watchCustomerOrderHistory(String userId) {
    if (userId.trim().isEmpty) {
      _customerOrderHistory = [];
      _watchedCustomerOrderHistoryId = null;
      _customerOrderHistorySubscription?.cancel();
      _customerOrderHistorySubscription = null;
      notifyListeners();
      return;
    }

    if (_watchedCustomerOrderHistoryId == userId && _customerOrderHistorySubscription != null) {
      return;
    }

    _watchedCustomerOrderHistoryId = userId;
    _customerOrderHistorySubscription?.cancel();
    _isLoadingCustomerOrderHistory = true;
    _customerOrderHistoryError = null;
    notifyListeners();

    _customerOrderHistorySubscription = _repository.watchUserOrders(userId).listen(
      (history) {
        _customerOrderHistory = history;
        _isLoadingCustomerOrderHistory = false;
        _customerOrderHistoryError = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoadingCustomerOrderHistory = false;
        _customerOrderHistoryError = 'Failed to load order history: $error';
        notifyListeners();
      },
    );
  }

  /// Stops watching the customer's order history (e.g. when leaving
  /// Customer Order Details).
  void clearCustomerOrderHistory() {
    _watchedCustomerOrderHistoryId = null;
    _customerOrderHistorySubscription?.cancel();
    _customerOrderHistorySubscription = null;
    _customerOrderHistory = [];
  }
}