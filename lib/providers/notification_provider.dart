import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// Provider orchestrating real-time admin notification management and user-facing lists.
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<NotificationModel>>? _subscription;
  bool _isWatching = false;

  // --- Processing Action States ---
  bool _isProcessing = false;
  String? _processError;

  // --- Admin Filter & Search Query States ---
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'order', 'product', 'wishlist', 'promotion', 'review', 'system'
  String _recipientFilter = 'all'; // 'all', 'all_users', 'role_customer', 'role_admin', 'specific_users'

  // --- FCM & Settings State ---
  NotificationSettingsModel _settings = const NotificationSettingsModel();
  bool _permissionGranted = false;
  StreamSubscription<NotificationSettingsModel>? _settingsSubscription;

  NotificationProvider({required this.repository});

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isProcessing => _isProcessing;
  String? get processError => _processError;

  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get recipientFilter => _recipientFilter;

  NotificationSettingsModel get settings => _settings;
  bool get permissionGranted => _permissionGranted;

  /// Starts streaming all notifications and initializes settings and FCM.
  void watchNotifications([String? uid]) {
    if (_isWatching) return;
    _isWatching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Start FCM and settings sync
    if (uid != null) {
      initializeFcm(uid);
      watchNotificationSettings(uid);
    }

    _subscription?.cancel();
    _subscription = repository.watchAllNotifications().listen(
      (data) {
        _notifications = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Failed to load notifications: $error';
        _isWatching = false;
        notifyListeners();
      },
    );
  }

  /// Stops streaming notifications.
  void stopWatching() {
    _isWatching = false;
    _subscription?.cancel();
    _subscription = null;
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }

  // =========================================================
  // ADMIN FILTER / SEARCH SETTERS
  // =========================================================

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setRecipientFilter(String filter) {
    _recipientFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _typeFilter = 'all';
    _recipientFilter = 'all';
    notifyListeners();
  }

  // =========================================================
  // USER NOTIFICATION GETTERS
  // =========================================================

  /// Returns active notifications targeted for the current customer user.
  List<NotificationModel> getUserNotifications(String uid, String role) {
    final List<NotificationModel> userList = [];
    for (final n in _notifications) {
      // Exclude if user has deleted it locally
      if (n.isDeletedBy(uid)) continue;

      // Filter by targeting
      if (n.recipientType == 'all') {
        userList.add(n);
      } else if (n.recipientType == 'role' && n.recipientRole == role) {
        userList.add(n);
      } else if (n.recipientType == 'users' && n.recipientIds.contains(uid)) {
        userList.add(n);
      }
    }

    // Sort: Newest first
    userList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(userList);
  }

  /// Counts unread notifications targeted for the current customer user.
  int getUnreadCount(String uid, String role) {
    return getUserNotifications(uid, role).where((n) => !n.isReadBy(uid)).length;
  }

  // =========================================================
  // ADMIN COMPLETED NOTIFICATIONS QUERY LIST
  // =========================================================

  List<NotificationModel> get filteredNotifications {
    List<NotificationModel> list = List.from(_notifications);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((n) {
        final titleMatches = n.title.toLowerCase().contains(_searchQuery);
        final bodyMatches = n.body.toLowerCase().contains(_searchQuery);
        final idMatches = n.id.toLowerCase().contains(_searchQuery);
        return titleMatches || bodyMatches || idMatches;
      }).toList();
    }

    // 2. Type Filter
    if (_typeFilter != 'all') {
      list = list.where((n) => n.type == _typeFilter).toList();
    }

    // 3. Recipient Targeting Filter
    if (_recipientFilter != 'all') {
      switch (_recipientFilter) {
        case 'all_users':
          list = list.where((n) => n.recipientType == 'all').toList();
          break;
        case 'role_customer':
          list = list.where((n) => n.recipientType == 'role' && n.recipientRole == 'customer').toList();
          break;
        case 'role_admin':
          list = list.where((n) => n.recipientType == 'role' && n.recipientRole == 'admin').toList();
          break;
        case 'specific_users':
          list = list.where((n) => n.recipientType == 'users').toList();
          break;
      }
    }

    // Sort: Newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  // =========================================================
  // ASYNC MUTATION ACTIONS
  // =========================================================

  Future<bool> _executeAction(Future<void> action) async {
    _isProcessing = true;
    _processError = null;
    notifyListeners();

    try {
      await action;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      _processError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- User Operations ---

  Future<bool> markAsRead(String id, String uid) {
    return _executeAction(repository.markAsRead(id, uid));
  }

  Future<bool> markAllAsRead(String uid, String role) {
    final unread = getUserNotifications(uid, role).where((n) => !n.isReadBy(uid));
    if (unread.isEmpty) return Future.value(true);
    final ids = unread.map((n) => n.id).toList();
    return _executeAction(repository.markAllAsRead(ids, uid));
  }

  Future<bool> deleteNotificationForUser(String id, String uid) {
    return _executeAction(repository.markAsDeleted(id, uid));
  }

  Future<bool> deleteAllNotificationsForUser(String uid, String role) {
    final list = getUserNotifications(uid, role);
    if (list.isEmpty) return Future.value(true);
    final ids = list.map((n) => n.id).toList();
    return _executeAction(repository.deleteAllNotifications(ids, uid));
  }

  // --- Admin Operations ---

  Future<bool> createNotification({
    required String title,
    required String body,
    required String type,
    required String recipientType,
    String? recipientRole,
    List<String>? recipientIds,
    DateTime? scheduledAt,
  }) {
    final now = DateTime.now();
    final newNotif = NotificationModel(
      id: '',
      title: title,
      body: body,
      type: type,
      recipientType: recipientType,
      recipientRole: recipientRole,
      recipientIds: recipientIds ?? [],
      readBy: [],
      deletedBy: [],
      scheduledAt: scheduledAt,
      createdAt: now,
      updatedAt: now,
    );
    return _executeAction(repository.createNotification(newNotif));
  }

  Future<bool> updateNotification(NotificationModel notification) {
    final updated = notification.copyWith(updatedAt: DateTime.now());
    return _executeAction(repository.updateNotification(updated));
  }

  Future<bool> deleteNotificationPermanently(String id) {
    final updated = repository.deleteNotification(id);
    return _executeAction(updated);
  }

  // =========================================================
  // FCM & SETTINGS MUTATION ACTIONS
  // =========================================================

  Future<void> initializeFcm(String uid) async {
    try {
      await repository.initializeFcm(uid);
      _permissionGranted = await repository.checkPermissionStatus();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing FCM in provider: $e");
      }
    }
  }

  Future<void> checkPermission() async {
    try {
      _permissionGranted = await repository.checkPermissionStatus();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> requestPermission(String uid) async {
    try {
      final granted = await repository.requestNotificationPermission(uid);
      _permissionGranted = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void watchNotificationSettings(String uid) {
    _settingsSubscription?.cancel();
    _settingsSubscription = repository.watchNotificationSettings(uid).listen(
      (newSettings) {
        _settings = newSettings;
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print("Error watching notification settings: $error");
        }
      },
    );
  }

  Future<bool> updateNotificationSettings(String uid, NotificationSettingsModel newSettings) async {
    return _executeAction(repository.updateNotificationSettings(uid, newSettings));
  }

  Future<void> removeTokenOnLogout() async {
    try {
      final token = repository.currentDeviceToken;
      if (token != null) {
        await repository.removeDeviceToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error removing token on logout: $e");
      }
    }
  }
}

extension NotificationModelExtension on NotificationModel {
  String get deliveryStatus {
    if (scheduledAt != null && scheduledAt!.isAfter(DateTime.now())) {
      return 'scheduled';
    }
    // Simulate failed status based on title context or deterministic ID hash
    final isFailed = title.toLowerCase().contains('fail') ||
        body.toLowerCase().contains('fail') ||
        title.toLowerCase().contains('[failed]') ||
        (id.isNotEmpty && id.hashCode % 9 == 0);
    return isFailed ? 'failed' : 'sent';
  }
}
