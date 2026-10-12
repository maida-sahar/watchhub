import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import 'storage_service.dart';

/// Custom exception type thrown by [CategoryService].
class CategoryServiceException implements Exception {
  final String message;
  final Object? cause;

  const CategoryServiceException(this.message, [this.cause]);

  @override
  String toString() => 'CategoryServiceException: $message';
}

/// CategoryService
///
/// Responsible ONLY for direct communication with Firebase
/// (Cloud Firestore + Supabase Storage) for the `categories` collection.
class CategoryService {
  CategoryService({
    FirebaseFirestore? firestore,
    StorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  /// Firestore collection reference for `categories`.
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  /// Root Storage folder under which all category images live.
  static const String _storageFolder = 'categories';

  // =========================================================
  // PUBLIC API
  // =========================================================

  /// Creates a new category.
  Future<CategoryModel> addCategory({
    required String name,
    String description = '',
    required XFile imageFile,
    required XFile iconFile,
    required XFile bannerFile,
    bool isActive = true,
    int displayOrder = 0,
  }) async {
    _validateNonEmpty(name, fieldName: 'name');
    await _validateFileExists(imageFile, fieldName: 'imageFile');
    await _validateFileExists(iconFile, fieldName: 'iconFile');
    await _validateFileExists(bannerFile, fieldName: 'bannerFile');

    final docRef = _categoriesRef.doc();
    final categoryId = docRef.id;

    String? imageUrl;
    String? iconUrl;
    String? bannerUrl;

    try {
      imageUrl = await _uploadFile(file: imageFile);
      iconUrl = await _uploadFile(file: iconFile);
      bannerUrl = await _uploadFile(file: bannerFile);

      final now = DateTime.now();
      final category = CategoryModel(
        id: categoryId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        iconUrl: iconUrl,
        bannerUrl: bannerUrl,
        isActive: isActive,
        displayOrder: displayOrder,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(category.toMap());
      return category;
    } on CategoryServiceException {
      // Cleanup uploaded files on failure
      if (imageUrl != null) await _storage.deleteImage(imageUrl);
      if (iconUrl != null) await _storage.deleteImage(iconUrl);
      if (bannerUrl != null) await _storage.deleteImage(bannerUrl);
      rethrow;
    } catch (e) {
      if (imageUrl != null) await _storage.deleteImage(imageUrl);
      if (iconUrl != null) await _storage.deleteImage(iconUrl);
      if (bannerUrl != null) await _storage.deleteImage(bannerUrl);
      throw _mapError(e, context: 'adding category');
    }
  }

  /// Returns all categories.
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final snapshot =
          await _categoriesRef.orderBy('displayOrder', descending: false).get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _mapError(e, context: 'fetching all categories');
    }
  }

  /// Returns only active categories.
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final snapshot = await _categoriesRef
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _mapError(e, context: 'fetching active categories');
    }
  }

  /// Fetches a single category by its document id.
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      final doc = await _categoriesRef.doc(categoryId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CategoryModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw _mapError(e, context: 'fetching category by id');
    }
  }

  /// Updates an existing category.
  ///
  /// New files are uploaded first (without deleting the old ones); old
  /// files are only deleted from Storage after the Firestore write
  /// succeeds, and any newly-uploaded file is rolled back if the write
  /// fails. This avoids a failed Firestore update leaving Firestore
  /// pointing at an image that was already deleted from Storage (or
  /// leaving a freshly-uploaded file orphaned).
  Future<CategoryModel> updateCategory(
    CategoryModel category, {
    XFile? newImageFile,
    XFile? newIconFile,
    XFile? newBannerFile,
  }) async {
    _validateNonEmpty(category.id, fieldName: 'category.id');
    _validateNonEmpty(category.name, fieldName: 'name');

    String? uploadedImageUrl;
    String? uploadedIconUrl;
    String? uploadedBannerUrl;

    try {
      var imageUrl = category.imageUrl;
      var iconUrl = category.iconUrl;
      var bannerUrl = category.bannerUrl;

      if (newImageFile != null) {
        await _validateFileExists(newImageFile, fieldName: 'newImageFile');
        final uniqueName = _storage.generateUniqueFileName(newImageFile);
        imageUrl = await _storage.uploadImage(
          file: newImageFile,
          path: '$_storageFolder/$uniqueName',
        );
        uploadedImageUrl = imageUrl;
      }
      if (newIconFile != null) {
        await _validateFileExists(newIconFile, fieldName: 'newIconFile');
        final uniqueName = _storage.generateUniqueFileName(newIconFile);
        iconUrl = await _storage.uploadImage(
          file: newIconFile,
          path: '$_storageFolder/$uniqueName',
        );
        uploadedIconUrl = iconUrl;
      }
      if (newBannerFile != null) {
        await _validateFileExists(newBannerFile, fieldName: 'newBannerFile');
        final uniqueName = _storage.generateUniqueFileName(newBannerFile);
        bannerUrl = await _storage.uploadImage(
          file: newBannerFile,
          path: '$_storageFolder/$uniqueName',
        );
        uploadedBannerUrl = bannerUrl;
      }

      final oldImageToRemove =
          (newImageFile != null && category.imageUrl.isNotEmpty) ? category.imageUrl : null;
      final oldIconToRemove =
          (newIconFile != null && category.iconUrl.isNotEmpty) ? category.iconUrl : null;
      final oldBannerToRemove =
          (newBannerFile != null && category.bannerUrl.isNotEmpty) ? category.bannerUrl : null;

      final updated = category.copyWith(
        imageUrl: imageUrl,
        iconUrl: iconUrl,
        bannerUrl: bannerUrl,
        updatedAt: DateTime.now(),
      );

      await _categoriesRef.doc(category.id).update(updated.toMap());

      // Firestore write succeeded — now safe to remove the old files.
      if (oldImageToRemove != null) await _storage.deleteImage(oldImageToRemove);
      if (oldIconToRemove != null) await _storage.deleteImage(oldIconToRemove);
      if (oldBannerToRemove != null) await _storage.deleteImage(oldBannerToRemove);

      return updated;
    } on CategoryServiceException {
      if (uploadedImageUrl != null) await _storage.deleteImage(uploadedImageUrl);
      if (uploadedIconUrl != null) await _storage.deleteImage(uploadedIconUrl);
      if (uploadedBannerUrl != null) await _storage.deleteImage(uploadedBannerUrl);
      rethrow;
    } catch (e) {
      if (uploadedImageUrl != null) await _storage.deleteImage(uploadedImageUrl);
      if (uploadedIconUrl != null) await _storage.deleteImage(uploadedIconUrl);
      if (uploadedBannerUrl != null) await _storage.deleteImage(uploadedBannerUrl);
      throw _mapError(e, context: 'updating category');
    }
  }

  /// Deletes a category document and all of its associated files.
  Future<void> deleteCategory(String categoryId) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      final category = await getCategoryById(categoryId);
      await _categoriesRef.doc(categoryId).delete();
      if (category != null) {
        if (category.imageUrl.isNotEmpty) {
          await _storage.deleteImage(category.imageUrl);
        }
        if (category.iconUrl.isNotEmpty) {
          await _storage.deleteImage(category.iconUrl);
        }
        if (category.bannerUrl.isNotEmpty) {
          await _storage.deleteImage(category.bannerUrl);
        }
      }
    } catch (e) {
      throw _mapError(e, context: 'deleting category');
    }
  }

  /// Enables or disables a category.
  Future<void> toggleCategoryStatus({
    required String categoryId,
    required bool isActive,
  }) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      await _categoriesRef.doc(categoryId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: 'toggling category status');
    }
  }

  /// Updates display order.
  Future<void> updateDisplayOrder({
    required String categoryId,
    required int displayOrder,
  }) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      await _categoriesRef.doc(categoryId).update({
        'displayOrder': displayOrder,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: 'updating display order');
    }
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Uploads a single file.
  Future<String> _uploadFile({
    required XFile file,
  }) async {
    try {
      final uniqueName = _storage.generateUniqueFileName(file);
      return await _storage.uploadImage(
        file: file,
        path: '$_storageFolder/$uniqueName',
      );
    } on StorageServiceException catch (e) {
      throw CategoryServiceException('Failed to upload file: ${e.message}', e);
    } catch (e) {
      throw CategoryServiceException('Failed to upload file', e);
    }
  }

  /// Throws [CategoryServiceException] if [value] is empty.
  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw CategoryServiceException('$fieldName cannot be empty.');
    }
  }

  /// Throws [CategoryServiceException] if [file] does not exist.
  Future<void> _validateFileExists(XFile file, {required String fieldName}) async {
    try {
      final len = await file.length();
      if (len == 0) {
        throw CategoryServiceException(
          'Missing file: $fieldName is empty.',
        );
      }
    } catch (e) {
      throw CategoryServiceException(
        'Missing file: $fieldName does not exist at ${file.path}.',
        e,
      );
    }
  }

  /// Maps exception.
  CategoryServiceException _mapError(Object error, {required String context}) {
    if (error is CategoryServiceException) return error;

    if (error is StorageServiceException) {
      return CategoryServiceException(error.message, error);
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return CategoryServiceException(
            'Permission denied while $context. Check Firestore/Storage rules.',
            error,
          );
        case 'unavailable':
        case 'network-request-failed':
          return CategoryServiceException(
            'Network error while $context. Please check your connection.',
            error,
          );
        case 'not-found':
          return CategoryServiceException(
            'Requested data was not found while $context.',
            error,
          );
        default:
          return CategoryServiceException(
            'Firebase error while $context: ${error.message ?? error.code}',
            error,
          );
      }
    }

    return CategoryServiceException('Unexpected error while $context.', error);
  }
}