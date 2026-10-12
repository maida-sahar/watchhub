import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';
import '../models/notification_model.dart';

class SettingsServiceException implements Exception {
  final String message;
  final String? code;
  const SettingsServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class SettingsService {
  final FirebaseFirestore _firestore;

  SettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches settings for a given user.
  /// If settings do not exist in the settings collection, it will fetch the
  /// profile data from the users collection and return a default settings model populated with that profile.
  Future<SettingsModel> fetchSettings(String userId) async {
    if (userId.trim().isEmpty) {
      throw const SettingsServiceException('User ID cannot be empty.');
    }

    try {
      // 1. Fetch settings from settings collection
      final settingsDoc = await _firestore.collection('settings').doc(userId).get();
      
      // 2. Fetch profile from users collection (always get fresh profile info)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userProfileMap = userDoc.exists ? userDoc.data() : null;
      final UserProfileSettings profile = UserProfileSettings(
        name: userProfileMap?['name'] ?? '',
        email: userProfileMap?['email'] ?? '',
        phone: userProfileMap?['phone'] ?? '',
        photoUrl: userProfileMap?['photoUrl'] ?? '',
      );

      // 3. Fetch notifications from notification_settings collection (keep synced)
      final notifDoc = await _firestore.collection('notification_settings').doc(userId).get();
      final notifications = notifDoc.exists
          ? NotificationSettingsModel.fromMap(notifDoc.data()!)
          : const NotificationSettingsModel();

      // 4. Fetch global admin settings
      final adminDoc = await _firestore.collection('settings').doc('admin').get();
      final admin = adminDoc.exists && adminDoc.data() != null
          ? AdminSettings.fromMap(adminDoc.data()!)
          : const AdminSettings();

      if (settingsDoc.exists && settingsDoc.data() != null) {
        final data = settingsDoc.data()!;
        final settings = SettingsModel.fromMap(data, userId);
        
        // Return settings with fresh profile, notifications and admin data
        return settings.copyWith(
          profile: profile,
          notifications: notifications,
          admin: admin,
        );
      }

      // Return default settings model if settings document doesn't exist
      return SettingsModel(
        userId: userId,
        profile: profile,
        notifications: notifications,
        admin: admin,
      );
    } on FirebaseException catch (e) {
      throw SettingsServiceException(e.message ?? 'Failed to fetch settings from Firestore', code: e.code);
    } catch (e) {
      throw SettingsServiceException('An unexpected error occurred while fetching settings: $e');
    }
  }

  /// Updates settings in Firestore across respective collections.
  Future<void> updateSettings(SettingsModel settings) async {
    final userId = settings.userId;
    if (userId.trim().isEmpty) {
      throw const SettingsServiceException('User ID cannot be empty.');
    }

    try {
      final batch = _firestore.batch();

      // 1. Update settings collection
      final settingsRef = _firestore.collection('settings').doc(userId);
      batch.set(settingsRef, settings.toMap(), SetOptions(merge: true));

      // 2. Update profile inside users collection
      //
      // Uses set(..., merge: true) rather than update(): update() throws
      // if the target document doesn't exist yet, which — inside a batch
      // — fails the ENTIRE batch.commit() atomically, meaning even the
      // profile/notification writes above would silently fail too if a
      // user's `users/{uid}` doc hadn't been created yet for any reason.
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(
        userRef,
        {
          'name': settings.profile.name,
          'phone': settings.profile.phone,
          'photoUrl': settings.profile.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Update notification settings collection
      final notifRef = _firestore.collection('notification_settings').doc(userId);
      batch.set(notifRef, settings.notifications.toMap()..['updatedAt'] = FieldValue.serverTimestamp(), SetOptions(merge: true));

      await batch.commit();
    } on FirebaseException catch (e) {
      throw SettingsServiceException(e.message ?? 'Failed to update settings in Firestore', code: e.code);
    } catch (e) {
      throw SettingsServiceException('An unexpected error occurred while updating settings: $e');
    }
  }

  /// Fetches global admin/store settings.
  Future<AdminSettings> fetchAdminSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('admin').get();
      if (doc.exists && doc.data() != null) {
        return AdminSettings.fromMap(doc.data()!);
      }
      return const AdminSettings();
    } on FirebaseException catch (e) {
      throw SettingsServiceException(e.message ?? 'Failed to fetch admin settings from Firestore', code: e.code);
    } catch (e) {
      throw SettingsServiceException('An unexpected error occurred while fetching admin settings: $e');
    }
  }

  /// Updates global admin/store settings.
  Future<void> updateAdminSettings(AdminSettings admin) async {
    try {
      await _firestore.collection('settings').doc('admin').set(
        admin.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw SettingsServiceException(e.message ?? 'Failed to update admin settings in Firestore', code: e.code);
    } catch (e) {
      throw SettingsServiceException('An unexpected error occurred while updating admin settings: $e');
    }
  }
}
