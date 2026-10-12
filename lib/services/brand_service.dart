import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_model.dart';
import 'storage_service.dart';

/// Custom exception type thrown by [BrandService].
class BrandServiceException implements Exception {
  final String message;
  final Object? cause;

  const BrandServiceException(this.message, [this.cause]);

  @override
  String toString() => 'BrandServiceException: $message';
}

/// BrandService
///
/// Responsible ONLY for direct communication with Firebase
/// (Cloud Firestore + Supabase Storage) for the `brands` collection.
class BrandService {
  BrandService({
    FirebaseFirestore? firestore,
    StorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  /// Firestore collection reference for `brands`.
  CollectionReference<Map<String, dynamic>> get _brandsRef =>
      _firestore.collection('brands');

  /// Storage folder for brand logos.
  static const String _logosFolder = 'brands';

  /// Storage folder for brand banners.
  static const String _bannersFolder = 'banners';

  // =========================================================
  // PUBLIC API — READS
  // =========================================================

  /// Returns all brands.
  Future<List<BrandModel>> getAllBrands() async {
    try {
      final snapshot =
          await _brandsRef.orderBy('displayOrder', descending: false).get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching all brands');
    }
  }

  /// Returns only active brands.
  Future<List<BrandModel>> getActiveBrands() async {
    try {
      final snapshot = await _brandsRef
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching active brands');
    }
  }

  /// Returns featured brands.
  Future<List<BrandModel>> getFeaturedBrands() async {
    try {
      final snapshot = await _brandsRef
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching featured brands');
    }
  }

  /// Fetches a single brand by its document id.
  Future<BrandModel?> getBrandById(String id) async {
    _validateNonEmpty(id, fieldName: 'id');
    try {
      final doc = await _brandsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return BrandModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw _mapError(e, context: 'fetching brand by id');
    }
  }

  /// Checks whether a brand named [name] already exists.
  Future<bool> brandNameExists(String name) async {
    final trimmedName = name.trim();
    _validateNonEmpty(trimmedName, fieldName: 'name');
    try {
      final snapshot = await _brandsRef
          .where('name', isEqualTo: trimmedName)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw _mapError(e, context: 'checking for duplicate brand name');
    }
  }

  // =========================================================
  // PUBLIC API — WRITES
  // =========================================================

  /// Creates a new brand document in Firestore after uploading logos/banners.
  Future<BrandModel> createBrand({
    required String name,
    required XFile logoFile,
    required XFile bannerFile,
    String description = '',
    String country = '',
    String website = '',
    bool isFeatured = false,
    bool isActive = true,
    int displayOrder = 0,
  }) async {
    _validateNonEmpty(name, fieldName: 'name');
    await _validateFileExists(logoFile, fieldName: 'logoFile');
    await _validateFileExists(bannerFile, fieldName: 'bannerFile');

    final nameTaken = await brandNameExists(name);
    if (nameTaken) {
      throw BrandServiceException('A brand named "$name" already exists.');
    }

    final docRef = _brandsRef.doc();
    final brandId = docRef.id;

    String? logoUrl;
    String? bannerUrl;

    try {
      final logoUnique = _storage.generateUniqueFileName(logoFile);
      logoUrl = await _storage.uploadImage(
        file: logoFile,
        path: '$_logosFolder/$logoUnique',
      );

      final bannerUnique = _storage.generateUniqueFileName(bannerFile);
      bannerUrl = await _storage.uploadImage(
        file: bannerFile,
        path: '$_bannersFolder/$bannerUnique',
      );

      final now = DateTime.now();
      final brand = BrandModel(
        id: brandId,
        name: name,
        description: description,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        website: website,
        country: country,
        isFeatured: isFeatured,
        isActive: isActive,
        displayOrder: displayOrder,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(brand.toMap());
      return brand;
    } on BrandServiceException {
      if (logoUrl != null) await _storage.deleteImage(logoUrl);
      if (bannerUrl != null) await _storage.deleteImage(bannerUrl);
      rethrow;
    } catch (e) {
      if (logoUrl != null) await _storage.deleteImage(logoUrl);
      if (bannerUrl != null) await _storage.deleteImage(bannerUrl);
      throw _mapError(e, context: 'creating brand');
    }
  }

  /// Updates an existing brand document in Firestore and replaces storage files.
  ///
  /// New logo/banner files are uploaded as brand-new objects first; the old
  /// ones are only deleted from Storage after the Firestore write succeeds,
  /// and any newly-uploaded file is rolled back if the write fails. This
  /// avoids a failed Firestore update leaving Firestore pointing at an old
  /// logo/banner that had already been deleted from Storage (or leaving a
  /// freshly-uploaded file orphaned).
  Future<BrandModel> updateBrand(
    BrandModel brand, {
    XFile? newLogoFile,
    XFile? newBannerFile,
  }) async {
    _validateNonEmpty(brand.id, fieldName: 'brand.id');

    String? uploadedLogoUrl;
    String? uploadedBannerUrl;

    try {
      var logoUrl = brand.logoUrl;
      var bannerUrl = brand.bannerUrl;

      if (newLogoFile != null) {
        await _validateFileExists(newLogoFile, fieldName: 'newLogoFile');
        final uniqueName = _storage.generateUniqueFileName(newLogoFile);
        logoUrl = await _storage.uploadImage(
          file: newLogoFile,
          path: '$_logosFolder/$uniqueName',
        );
        uploadedLogoUrl = logoUrl;
      }

      if (newBannerFile != null) {
        await _validateFileExists(newBannerFile, fieldName: 'newBannerFile');
        final uniqueName = _storage.generateUniqueFileName(newBannerFile);
        bannerUrl = await _storage.uploadImage(
          file: newBannerFile,
          path: '$_bannersFolder/$uniqueName',
        );
        uploadedBannerUrl = bannerUrl;
      }

      final oldLogoToRemove =
          (newLogoFile != null && brand.logoUrl.isNotEmpty) ? brand.logoUrl : null;
      final oldBannerToRemove =
          (newBannerFile != null && brand.bannerUrl.isNotEmpty) ? brand.bannerUrl : null;

      final updated = brand.copyWith(
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        updatedAt: DateTime.now(),
      );

      await _brandsRef.doc(brand.id).update(updated.toMap());

      // Firestore write succeeded — now safe to remove the old files.
      if (oldLogoToRemove != null) await _storage.deleteImage(oldLogoToRemove);
      if (oldBannerToRemove != null) await _storage.deleteImage(oldBannerToRemove);

      return updated;
    } on BrandServiceException {
      if (uploadedLogoUrl != null) await _storage.deleteImage(uploadedLogoUrl);
      if (uploadedBannerUrl != null) await _storage.deleteImage(uploadedBannerUrl);
      rethrow;
    } catch (e) {
      if (uploadedLogoUrl != null) await _storage.deleteImage(uploadedLogoUrl);
      if (uploadedBannerUrl != null) await _storage.deleteImage(uploadedBannerUrl);
      throw _mapError(e, context: 'updating brand');
    }
  }

  /// Deletes a brand document and attempts to delete its images.
  Future<void> deleteBrand(String brandId) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      final brand = await getBrandById(brandId);
      await _brandsRef.doc(brandId).delete();

      if (brand != null) {
        if (brand.logoUrl.isNotEmpty) {
          await _storage.deleteImage(brand.logoUrl);
        }
        if (brand.bannerUrl.isNotEmpty) {
          await _storage.deleteImage(brand.bannerUrl);
        }
      }
    } catch (e) {
      throw _mapError(e, context: 'deleting brand');
    }
  }

  /// Toggles the `isActive` flag in Firestore.
  Future<void> toggleBrandStatus(String brandId, bool isActive) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      await _brandsRef.doc(brandId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: 'toggling brand status');
    }
  }

  /// Updates the `displayOrder` sorting field in Firestore.
  Future<void> updateDisplayOrder(String brandId, int displayOrder) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    if (displayOrder < 0) {
      throw const BrandServiceException('displayOrder cannot be negative.');
    }
    try {
      await _brandsRef.doc(brandId).update({
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

  List<BrandModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => BrandModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw BrandServiceException('$fieldName cannot be empty.');
    }
  }

  Future<void> _validateFileExists(XFile file, {required String fieldName}) async {
    try {
      final len = await file.length();
      if (len == 0) {
        throw BrandServiceException(
          'Missing file: $fieldName is empty.',
        );
      }
    } catch (e) {
      throw BrandServiceException(
        'Missing file: $fieldName does not exist at ${file.path}.',
        e,
      );
    }
  }

  BrandServiceException _mapError(Object error, {required String context}) {
    if (error is BrandServiceException) return error;

    if (error is StorageServiceException) {
      return BrandServiceException(error.message, error);
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return BrandServiceException(
            'Permission denied while $context. Check Firestore/Storage rules.',
            error,
          );
        case 'unavailable':
        case 'network-request-failed':
          return BrandServiceException(
            'Network error while $context. Please check your connection.',
            error,
          );
        case 'not-found':
          return BrandServiceException(
            'Requested data was not found while $context.',
            error,
          );
        default:
          return BrandServiceException(
            'Firebase error while $context: ${error.message ?? error.code}',
            error,
          );
      }
    }

    return BrandServiceException('Unexpected error while $context.', error);
  }
}