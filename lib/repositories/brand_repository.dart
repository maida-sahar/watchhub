import 'package:image_picker/image_picker.dart';

import '../models/brand_model.dart';
import '../services/brand_service.dart';

/// Custom exception type thrown by [BrandRepository].
class BrandRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const BrandRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'BrandRepositoryException: $message';
}

/// BrandRepository
///
/// Owns every business rule for brands and is the ONLY layer
/// [BrandProvider] should talk to:
///
///   Provider → BrandRepository → BrandService → Firebase
///
/// This class communicates ONLY with [BrandService] — it never imports
/// `cloud_firestore` or `firebase_storage` directly, and never talks to
/// UI.
class BrandRepository {
  BrandRepository({required BrandService service}) : _service = service;

  final BrandService _service;

  // =========================================================
  // READS
  // =========================================================

  /// Returns all brands.
  Future<List<BrandModel>> getAllBrands() async {
    try {
      return await _service.getAllBrands();
    } catch (e) {
      throw _mapError(e, context: 'fetching all brands');
    }
  }

  /// Returns only active brands.
  Future<List<BrandModel>> getActiveBrands() async {
    try {
      return await _service.getActiveBrands();
    } catch (e) {
      throw _mapError(e, context: 'fetching active brands');
    }
  }

  /// Returns active brands flagged as featured.
  Future<List<BrandModel>> getFeaturedBrands() async {
    try {
      return await _service.getFeaturedBrands();
    } catch (e) {
      throw _mapError(e, context: 'fetching featured brands');
    }
  }

  /// Fetches a single brand by id, or `null` if it doesn't exist.
  Future<BrandModel?> getBrandById(String id) async {
    _validateNonEmpty(id, fieldName: 'id');
    try {
      return await _service.getBrandById(id);
    } catch (e) {
      throw _mapError(e, context: 'fetching brand by id');
    }
  }

  /// Checks whether a brand named [name] already exists.
  Future<bool> brandNameExists(String name) async {
    final trimmed = name.trim();
    _validateNonEmpty(trimmed, fieldName: 'name');
    try {
      return await _service.brandNameExists(trimmed);
    } catch (e) {
      throw _mapError(e, context: 'checking for duplicate brand name');
    }
  }

  // =========================================================
  // WRITES
  // =========================================================

  /// Creates a new brand.
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
    try {
      final nameTaken = await _service.brandNameExists(name);
      if (nameTaken) {
        throw BrandRepositoryException('A brand named "$name" already exists.');
      }
      return await _service.createBrand(
        name: name,
        logoFile: logoFile,
        bannerFile: bannerFile,
        description: description,
        country: country,
        website: website,
        isFeatured: isFeatured,
        isActive: isActive,
        displayOrder: displayOrder,
      );
    } catch (e) {
      throw _mapError(e, context: 'creating brand');
    }
  }

  /// Updates an existing brand.
  Future<BrandModel> updateBrand(
    BrandModel brand, {
    XFile? newLogoFile,
    XFile? newBannerFile,
  }) async {
    _validateNonEmpty(brand.id, fieldName: 'brand.id');
    try {
      final trimmedName = brand.name.trim();
      final current = await _service.getBrandById(brand.id);

      if (current == null) {
        throw BrandRepositoryException(
          'Brand with id "${brand.id}" was not found.',
        );
      }

      final nameChanged =
          current.name.trim().toLowerCase() != trimmedName.toLowerCase();
      if (nameChanged) {
        final nameTaken = await _service.brandNameExists(trimmedName);
        if (nameTaken) {
          throw BrandRepositoryException(
            'A brand named "$trimmedName" already exists.',
          );
        }
      }

      final sanitized = brand.copyWith(name: trimmedName);
      return await _service.updateBrand(
        sanitized,
        newLogoFile: newLogoFile,
        newBannerFile: newBannerFile,
      );
    } on BrandRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'updating brand');
    }
  }

  /// Deletes a brand's Firestore document and its Storage images.
  Future<void> deleteBrand(String brandId) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      await _service.deleteBrand(brandId);
    } catch (e) {
      throw _mapError(e, context: 'deleting brand');
    }
  }

  /// Enables or disables a brand.
  Future<void> toggleBrandStatus(String brandId, bool isActive) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      await _service.toggleBrandStatus(brandId, isActive);
    } catch (e) {
      throw _mapError(e, context: 'toggling brand status');
    }
  }

  /// Updates a brand's displayOrder.
  Future<void> updateDisplayOrder(String brandId, int displayOrder) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    if (displayOrder < 0) {
      throw const BrandRepositoryException(
        'displayOrder cannot be negative.',
      );
    }
    try {
      await _service.updateDisplayOrder(brandId, displayOrder);
    } catch (e) {
      throw _mapError(e, context: 'updating display order');
    }
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw BrandRepositoryException('$fieldName cannot be empty.');
    }
  }

  BrandRepositoryException _mapError(Object error, {required String context}) {
    if (error is BrandRepositoryException) return error;

    if (error is BrandServiceException) {
      return BrandRepositoryException(error.message, error);
    }

    if (error is ArgumentError) {
      return BrandRepositoryException(
        error.message?.toString() ?? 'Invalid brand data while $context.',
        error,
      );
    }

    return BrandRepositoryException('Unexpected error while $context.', error);
  }
}