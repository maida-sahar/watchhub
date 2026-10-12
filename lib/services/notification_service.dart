import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../config/app_router.dart';
import '../config/app_routes.dart';

/// Exception wrapper for NotificationService failures.
class NotificationServiceException implements Exception {
  final String message;
  final String? code;
  const NotificationServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

// Global top-level background handler for FCM. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Background message received: ${message.messageId}");
  }
}

/// Service handling Firestore access for admin and customer notifications,
/// as well as Firebase Cloud Messaging integration.
class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const String _notificationsCollection = 'notifications';
  String? _deviceToken;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(_notificationsCollection);

  String? get currentDeviceToken => _deviceToken;

  /// Initializes FCM and local notifications for a user session.
  Future<void> initialize(String uid) async {
    try {
      // 1. Initialize background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleLocalNotificationTap(response.payload);
        },
      );

      // 3. Request permissions & upload token
      await requestNotificationPermission(uid);

      // 4. Setup Token Refresh Listener
      _messaging.onTokenRefresh.listen((token) async {
        _deviceToken = token;
        await saveDeviceToken(uid, token);
      });

      // 5. Setup foreground & background message streams
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(uid, message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 6. Check initial message (Terminated app state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing FCM in NotificationService: $e");
      }
    }
  }

  /// Checks if the notification permissions are granted.
  Future<bool> checkPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Requests notification permissions and fetches/registers the FCM device token.
  Future<bool> requestNotificationPermission(String uid) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        final token = await _messaging.getToken();
        if (token != null) {
          _deviceToken = token;
          await saveDeviceToken(uid, token);
        }
      }
      return granted;
    } catch (e) {
      throw NotificationServiceException("Failed to request notification permission: $e");
    }
  }

  /// Saves the FCM device token to Firestore.
  Future<void> saveDeviceToken(String uid, String token) async {
    try {
      await _firestore.collection('fcm_tokens').doc(token).set({
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore token write failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Removes the FCM device token from Firestore.
  Future<void> removeDeviceToken(String token) async {
    try {
      await _firestore.collection('fcm_tokens').doc(token).delete();
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore token delete failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Streams notification settings in real-time.
  Stream<NotificationSettingsModel> watchNotificationSettings(String uid) {
    return _firestore
        .collection('notification_settings')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const NotificationSettingsModel();
      }
      return NotificationSettingsModel.fromMap(snapshot.data()!);
    });
  }

  /// Updates notification settings in Firestore and subscribes/unsubscribes to topics.
  Future<void> updateNotificationSettings(String uid, NotificationSettingsModel settings) async {
    try {
      await _firestore.collection('notification_settings').doc(uid).set(
        settings.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
      await syncTopics(settings);
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore settings update failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Dynamic topic sync helper.
  Future<void> syncTopics(NotificationSettingsModel settings) async {
    try {
      if (settings.pushEnabled) {
        if (settings.promotionEnabled) {
          await _messaging.subscribeToTopic('promotions');
        } else {
          await _messaging.unsubscribeFromTopic('promotions');
        }
        if (settings.systemEnabled) {
          await _messaging.subscribeToTopic('system');
        } else {
          await _messaging.unsubscribeFromTopic('system');
        }
      } else {
        await _messaging.unsubscribeFromTopic('promotions');
        await _messaging.unsubscribeFromTopic('system');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to sync topics: $e");
      }
    }
  }

  /// Checks user preferences before showing a foreground notification.
  Future<void> _handleForegroundMessage(String uid, RemoteMessage message) async {
    try {
      final doc = await _firestore.collection('notification_settings').doc(uid).get();
      NotificationSettingsModel settings = const NotificationSettingsModel();
      if (doc.exists && doc.data() != null) {
        settings = NotificationSettingsModel.fromMap(doc.data()!);
      }

      if (!settings.pushEnabled) return;

      final type = message.data['type'] ?? message.notification?.title ?? '';
      final normalizedType = type.toString().toLowerCase().trim();

      bool show = true;
      if (normalizedType.contains('order') && !settings.orderEnabled) show = false;
      if (normalizedType.contains('promotion') && !settings.promotionEnabled) show = false;
      if (normalizedType.contains('wishlist') && !settings.wishlistEnabled) show = false;
      if (normalizedType.contains('review') && !settings.reviewEnabled) show = false;
      if (normalizedType.contains('system') && !settings.systemEnabled) show = false;

      if (show) {
        await _showForegroundLocalNotification(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking preferences in foreground message handler: $e");
      }
    }
  }

  /// Displays foreground notification using local notifications.
  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      final title = notification.title ?? '';
      final body = notification.body ?? '';

      const androidDetails = AndroidNotificationDetails(
        'watch_hub_channel',
        'WatchHub Notifications',
        channelDescription: 'Main channel for WatchHub notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const platformDetails = NotificationDetails(android: androidDetails);

      final type = message.data['type'] ?? 'system';
      final orderId = message.data['orderId'] ?? '';
      final payload = "$type|$orderId";

      await _localNotifications.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    }
  }

  /// Handles FCM notification taps/clicks.
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? 'system';
    final orderId = message.data['orderId'] ?? '';
    _navigateToScreen(type, orderId);
  }

  /// Handles Local Notification taps/clicks.
  void _handleLocalNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      final parts = payload.split('|');
      final type = parts[0];
      final orderId = parts.length > 1 ? parts[1] : '';
      _navigateToScreen(type, orderId);
    }
  }

  /// Handles actual navigation/deep-linking to the appropriate screen.
  void _navigateToScreen(String type, String orderId) {
    final state = AppRouter.navigatorKey.currentState;
    if (state == null) return;

    final normalizedType = type.toLowerCase().trim();

    if (normalizedType == 'order') {
      if (orderId.isNotEmpty) {
        state.pushNamed(AppRoutes.orderDetails, arguments: orderId);
      } else {
        state.pushNamed(AppRoutes.customerOrders);
      }
    } else if (normalizedType == 'wishlist') {
      state.pushNamed(AppRoutes.customerWishlist);
    } else if (normalizedType == 'promotion') {
      state.pushNamed(AppRoutes.customerHome);
    } else if (normalizedType == 'review') {
      state.pushNamed(AppRoutes.customerHome);
    } else {
      state.pushNamed(AppRoutes.notifications);
    }
  }

  // =========================================================
  // EXISTING FIRESTORE CRUD METHODS
  // =========================================================

  /// Streams all notifications in the system in real-time.
  Stream<List<NotificationModel>> watchAllNotifications() {
    return _notificationsRef.snapshots().map((snapshot) {
      final List<NotificationModel> notifications = [];
      for (final doc in snapshot.docs) {
        try {
          notifications.add(NotificationModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip invalid documents
        }
      }
      return notifications;
    });
  }

  /// Creates a new notification (Admin action).
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _notificationsRef.add(notification.toMap());
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore write failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Updates an existing notification (Admin action).
  Future<void> updateNotification(NotificationModel notification) async {
    try {
      await _notificationsRef.doc(notification.id).update(notification.toMap());
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore update failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Deletes a notification permanently (Admin action).
  Future<void> deleteNotification(String id) async {
    try {
      await _notificationsRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Firestore delete failed', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Marks a notification as read by a specific user.
  Future<void> markAsRead(String id, String uid) async {
    try {
      await _notificationsRef.doc(id).update({
        'readBy': FieldValue.arrayUnion([uid]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Failed to mark as read', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Marks a notification as deleted/dismissed locally by a specific user.
  Future<void> markAsDeleted(String id, String uid) async {
    try {
      await _notificationsRef.doc(id).update({
        'deletedBy': FieldValue.arrayUnion([uid]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Failed to delete notification locally', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Marks multiple notifications as read for a specific user.
  Future<void> markAllAsRead(List<String> ids, String uid) async {
    try {
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.update(_notificationsRef.doc(id), {
          'readBy': FieldValue.arrayUnion([uid]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Failed to mark all as read', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }

  /// Marks multiple notifications as deleted for a specific user.
  Future<void> deleteAllNotifications(List<String> ids, String uid) async {
    try {
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.update(_notificationsRef.doc(id), {
          'deletedBy': FieldValue.arrayUnion([uid]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw NotificationServiceException(e.message ?? 'Failed to delete all notifications', code: e.code);
    } catch (e) {
      throw NotificationServiceException('An unexpected error occurred: $e');
    }
  }
}
