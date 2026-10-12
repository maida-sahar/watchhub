import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'storage_service.dart';

/// Exception wrapper for UserService failures.
class UserServiceException implements Exception {
  final String message;
  final String? code;

  const UserServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service that interacts directly with Firestore for User profiles.
class UserService {
  final FirebaseFirestore _firestore;
  final StorageService _storage;

  static const String _usersCollection = 'users';

  UserService({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  /// Streams all registered users in the database.
  Stream<List<UserModel>> watchAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      final List<UserModel> users = [];
      for (final doc in snapshot.docs) {
        try {
          users.add(UserModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip malformed documents
        }
      }
      return users;
    });
  }

  /// Streams a single user profile by UID.
  Stream<UserModel?> watchUserById(String uid) {
    if (uid.trim().isEmpty) {
      return Stream.value(null);
    }
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      try {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      } catch (e) {
        throw UserServiceException('Malformed user data: $e');
      }
    });
  }

  /// Updates a customer's active and/or blocked status in Firestore.
  Future<void> updateCustomerStatus(String uid, {bool? isActive, bool? isBlocked}) async {
    if (uid.trim().isEmpty) {
      throw const UserServiceException('User UID is required to update status.');
    }

    final Map<String, dynamic> updates = {
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (isActive != null) {
      updates['isActive'] = isActive;
    }
    if (isBlocked != null) {
      updates['isBlocked'] = isBlocked;
    }

    try {
      await _usersRef.doc(uid).update(updates);
    } on FirebaseException catch (e) {
      throw UserServiceException(e.message ?? 'Failed to update user status.', code: e.code);
    } catch (e) {
      throw UserServiceException('An unexpected error occurred while updating status: $e');
    }
  }

  /// Uploads profile picture to Supabase and saves public URL inside Firestore.
  Future<String> updateUserProfilePicture({
    required String uid,
    required XFile imageFile,
    required String role,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) {
      throw const UserServiceException('User UID is required to update profile picture.');
    }
    try {
      if (await imageFile.length() == 0) {
        throw const UserServiceException('Image file is empty.');
      }
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw const UserServiceException('Image file does not exist or is invalid.');
    }

    // Determine storage folder path based on role with UID scoping
    String folder;
    if (role == UserRole.admin) {
      folder = 'profiles/admins/$cleanUid';
    } else if (role == UserRole.customer) {
      folder = 'profiles/customers/$cleanUid';
    } else {
      folder = 'profiles/users/$cleanUid';
    }

    try {
      final doc = await _usersRef.doc(cleanUid).get();
      if (!doc.exists) {
        throw const UserServiceException('User profile does not exist in database.');
      }

      final oldUrl = doc.data()?['photoUrl'] as String? ?? '';
      final uniqueName = _storage.generateUniqueFileName(imageFile);
      final newPath = '$folder/$uniqueName';

      final newUrl = await _storage.replaceImage(
        newFile: imageFile,
        path: newPath,
        oldPublicUrl: oldUrl,
      );

      await _usersRef.doc(cleanUid).update({
        'photoUrl': newUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return newUrl;
    } on StorageServiceException catch (e) {
      throw UserServiceException('Storage error: ${e.message}');
    } on FirebaseException catch (e) {
      throw UserServiceException('Database error: ${e.message ?? e.code}', code: e.code);
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('An unexpected error occurred: $e');
    }
  }
}
