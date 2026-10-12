import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

/// Exception specific to high-level user repository operations.
class UserRepositoryException implements Exception {
  final String message;
  const UserRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Repository to abstract user queries and Firestore operations.
class UserRepository {
  final UserService _service;

  UserRepository({required UserService service}) : _service = service;

  /// Exposes a real-time stream of all user documents.
  Stream<List<UserModel>> watchAllUsers() {
    return _service.watchAllUsers();
  }

  /// Exposes a real-time stream of a specific user document by UID.
  Stream<UserModel?> watchUserById(String uid) {
    return _service.watchUserById(uid);
  }

  /// Updates a customer's active and/or blocked status.
  Future<void> updateCustomerStatus(String uid, {bool? isActive, bool? isBlocked}) async {
    try {
      await _service.updateCustomerStatus(uid, isActive: isActive, isBlocked: isBlocked);
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  /// Uploads profile picture and saves public URL inside Firestore.
  Future<String> updateUserProfilePicture({
    required String uid,
    required XFile imageFile,
    required String role,
  }) async {
    try {
      return await _service.updateUserProfilePicture(
        uid: uid,
        imageFile: imageFile,
        role: role,
      );
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }
}
