import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/checkout_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/order_repository.dart';

/// Provider for managing customer profile lists, advanced filters, search, and aggregates.
class UserProvider extends ChangeNotifier {
  final UserRepository userRepository;
  final OrderRepository orderRepository;

  List<UserModel> _users = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  bool _isWatching = false;

  // --- Search & Filter States ---
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'active', 'inactive', 'new', 'with_orders', 'without_orders', 'top_spending'
  DateTimeRange? _dateRange; // Join Date Range Filter

  // --- Status Update States ---
  bool _isUpdatingStatus = false;
  String? _statusUpdateError;

  UserProvider({
    required this.userRepository,
    required this.orderRepository,
  });

  List<UserModel> get users => _users.where((u) => u.role == UserRole.customer).toList();
  List<UserModel> get customers => users;
  List<OrderModel> get allOrders => List.unmodifiable(_allOrders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get filterType => _filterType;
  DateTimeRange? get dateRange => _dateRange;

  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get statusUpdateError => _statusUpdateError;

  /// Subscribes to real-time updates for all users and all orders in the system.
  void watchCustomers() {
    if (_isWatching) return;
    _isWatching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _usersSubscription?.cancel();
    _usersSubscription = userRepository.watchAllUsers().listen(
      (updatedUsers) {
        _users = updatedUsers;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load customers: $error';
        _isLoading = false;
        _isWatching = false;
        notifyListeners();
      },
    );

    _ordersSubscription?.cancel();
    _ordersSubscription = orderRepository.watchAllOrders().listen(
      (updatedOrders) {
        _allOrders = updatedOrders;
        notifyListeners();
      },
      onError: (error) {
        // Order stats are supplementary; we handle quietly
      },
    );
  }

  /// Cancels subscriptions and stops watching data.
  void stopWatching() {
    _isWatching = false;
    _usersSubscription?.cancel();
    _usersSubscription = null;
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }

  // =========================================================
  // SEARCH & FILTER SETTERS
  // =========================================================

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _filterType = 'all';
    _dateRange = null;
    notifyListeners();
  }

  // =========================================================
  // COMPUTED REACTIVE FILTERED CUSTOMERS LIST
  // =========================================================

  List<UserModel> get filteredCustomers {
    // 1. Start with all customers
    List<UserModel> list = users;

    // 2. Filter by search query (name, email, or phone)
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) {
        final nameMatches = u.name.toLowerCase().contains(_searchQuery);
        final emailMatches = u.email.toLowerCase().contains(_searchQuery);
        final phoneMatches = u.phone.toLowerCase().contains(_searchQuery);
        return nameMatches || emailMatches || phoneMatches;
      }).toList();
    }

    // 3. Filter by date range (Join Date)
    if (_dateRange != null) {
      // Ensure range matches full days
      final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day, 0, 0, 0);
      final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
      list = list.where((u) => u.createdAt.isAfter(start) && u.createdAt.isBefore(end)).toList();
    }

    // 4. Filter by type
    switch (_filterType) {
      case 'active':
        list = list.where((u) => u.isActive).toList();
        break;
      case 'inactive':
        list = list.where((u) => !u.isActive).toList();
        break;
      case 'new':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        list = list.where((u) => u.createdAt.isAfter(thirtyDaysAgo)).toList();
        break;
      case 'with_orders':
        list = list.where((u) => getTotalOrders(u.uid) > 0).toList();
        break;
      case 'without_orders':
        list = list.where((u) => getTotalOrders(u.uid) == 0).toList();
        break;
      case 'top_spending':
        // Sort by spending descending
        list.sort((a, b) => getTotalSpending(b.uid).compareTo(getTotalSpending(a.uid)));
        return List.unmodifiable(list);
    }

    // Default sort: Join date descending
    if (_filterType != 'top_spending') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return List.unmodifiable(list);
  }

  // =========================================================
  // SINGLE CUSTOMER STATS HELPERS
  // =========================================================

  List<OrderModel> getOrdersForUser(String userId) {
    return _allOrders.where((o) => o.userId == userId).toList();
  }

  int getTotalOrders(String userId) {
    return getOrdersForUser(userId).length;
  }

  int getCompletedOrders(String userId) {
    return getOrdersForUser(userId)
        .where((o) => o.orderStatus.trim().toLowerCase() == 'delivered')
        .length;
  }

  int getPendingOrders(String userId) {
    return getOrdersForUser(userId)
        .where((o) => o.orderStatus.trim().toLowerCase() == 'pending')
        .length;
  }

  int getCancelledOrders(String userId) {
    return getOrdersForUser(userId)
        .where((o) => o.orderStatus.trim().toLowerCase() == 'cancelled')
        .length;
  }

  double getTotalSpending(String userId) {
    return getOrdersForUser(userId)
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled')
        .fold<double>(0.0, (sum, order) => sum + order.grandTotal);
  }

  ShippingAddress? getLatestShippingAddress(String userId) {
    final userOrders = getOrdersForUser(userId);
    if (userOrders.isEmpty) return null;
    final sorted = List<OrderModel>.from(userOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first.shippingAddress;
  }

  // =========================================================
  // GLOBAL STATISTICS GETTERS (ALL CUSTOMERS)
  // =========================================================

  int get totalCustomersCount => users.length;

  int get activeCustomersCount => users.where((u) => u.isActive).length;

  int get newCustomersCount {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return users.where((u) => u.createdAt.isAfter(thirtyDaysAgo)).length;
  }

  int get totalOrdersCount => _allOrders.length;

  int get completedOrdersCount =>
      _allOrders.where((o) => o.orderStatus.trim().toLowerCase() == 'delivered').length;

  int get pendingOrdersCount =>
      _allOrders.where((o) => o.orderStatus.trim().toLowerCase() == 'pending').length;

  int get cancelledOrdersCount =>
      _allOrders.where((o) => o.orderStatus.trim().toLowerCase() == 'cancelled').length;

  double get totalSpendingSum =>
      _allOrders.where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled')
          .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

  double get averageOrderValue {
    final nonCancelledOrdersCount = _allOrders
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled')
        .length;
    return nonCancelledOrdersCount > 0 ? (totalSpendingSum / nonCancelledOrdersCount) : 0.0;
  }

  DateTime? get lastOrderDate {
    if (_allOrders.isEmpty) return null;
    final sorted = List<OrderModel>.from(_allOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first.createdAt;
  }

  // =========================================================
  // STATUS CONTROL HANDLERS (ACTIVATE/DEACTIVATE/BLOCK/UNBLOCK)
  // =========================================================

  /// Updates customer active/inactive status in Firestore.
  Future<bool> updateCustomerActive(String uid, bool isActive) async {
    _isUpdatingStatus = true;
    _statusUpdateError = null;
    notifyListeners();

    try {
      await userRepository.updateCustomerStatus(uid, isActive: isActive);
      _isUpdatingStatus = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdatingStatus = false;
      _statusUpdateError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Updates customer blocked status in Firestore.
  Future<bool> updateCustomerBlocked(String uid, bool isBlocked) async {
    _isUpdatingStatus = true;
    _statusUpdateError = null;
    notifyListeners();

    try {
      await userRepository.updateCustomerStatus(uid, isBlocked: isBlocked);
      _isUpdatingStatus = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdatingStatus = false;
      _statusUpdateError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clears the status update error message
  void clearStatusUpdateError() {
    _statusUpdateError = null;
    notifyListeners();
  }

  // =========================================================
  // PROFILE PICTURE ACTIONS
  // =========================================================

  bool _isUploadingProfilePicture = false;
  String? _profilePictureError;

  bool get isUploadingProfilePicture => _isUploadingProfilePicture;
  String? get profilePictureError => _profilePictureError;

  Future<String?> updateUserProfilePicture({
    required String uid,
    required XFile imageFile,
    required String role,
  }) async {
    _isUploadingProfilePicture = true;
    _profilePictureError = null;
    notifyListeners();

    try {
      final url = await userRepository.updateUserProfilePicture(
        uid: uid,
        imageFile: imageFile,
        role: role,
      );
      _isUploadingProfilePicture = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isUploadingProfilePicture = false;
      _profilePictureError = e.toString();
      notifyListeners();
      return null;
    }
  }
}
