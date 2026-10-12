import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Exception wrapper for NotificationRepository failures.
class NotificationRepositoryException implements Exception {
  final String message;
  const NotificationRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Repository abstracting Firestore access for notifications.
class NotificationRepository {
  final NotificationService _service;

  NotificationRepository({required NotificationService service}) : _service = service;

  /// Exposes stream of all notifications.
  Stream<List<NotificationModel>> watchAllNotifications() {
    return _service.watchAllNotifications();
  }

  /// Creates a notification.
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _service.createNotification(notification);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Updates an existing notification.
  Future<void> updateNotification(NotificationModel notification) async {
    try {
      await _service.updateNotification(notification);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Deletes a notification permanently.
  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String id, String uid) async {
    try {
      await _service.markAsRead(id, uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Marks a notification as deleted.
  Future<void> markAsDeleted(String id, String uid) async {
    try {
      await _service.markAsDeleted(id, uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Marks multiple notifications as read.
  Future<void> markAllAsRead(List<String> ids, String uid) async {
    try {
      await _service.markAllAsRead(ids, uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  /// Marks multiple notifications as deleted.
  Future<void> deleteAllNotifications(List<String> ids, String uid) async {
    try {
      await _service.deleteAllNotifications(ids, uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  String? get currentDeviceToken => _service.currentDeviceToken;

  Future<void> initializeFcm(String uid) async {
    try {
      await _service.initialize(uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  Future<bool> checkPermissionStatus() async {
    try {
      return await _service.checkPermissionStatus();
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  Future<bool> requestNotificationPermission(String uid) async {
    try {
      return await _service.requestNotificationPermission(uid);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  Future<void> saveDeviceToken(String uid, String token) async {
    try {
      await _service.saveDeviceToken(uid, token);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  Future<void> removeDeviceToken(String token) async {
    try {
      await _service.removeDeviceToken(token);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }

  Stream<NotificationSettingsModel> watchNotificationSettings(String uid) {
    return _service.watchNotificationSettings(uid);
  }

  Future<void> updateNotificationSettings(String uid, NotificationSettingsModel settings) async {
    try {
      await _service.updateNotificationSettings(uid, settings);
    } catch (e) {
      throw NotificationRepositoryException(e.toString());
    }
  }
}
