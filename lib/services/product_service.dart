import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import 'storage_service.dart';

/// Custom exception type thrown by [ProductService].
class ProductServiceException implements Exception {
  final String message;
  final Object? cause;

  const ProductServiceException(this.message, [this.cause]);

  @override
  String toString() => 'ProductServiceException: $message';
}

/// ProductService
///
/// Responsible ONLY for direct communication with Firebase
/// (Cloud Firestore + Supabase Storage) for the `products` collection.
class ProductService {
  ProductService({
    FirebaseFirestore? firestore,
    StorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  /// Firestore collection reference for `products`.
  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Storage folder under which all product images live.
  static const String _productsFolder = 'products';

  // =========================================================
  // PUBLIC API — READS
  // =========================================================

  /// Returns all products (active and inactive).
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _productsRef.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching all products');
    }
  }

  /// Exposes a real-time stream of all products.
  Stream<List<ProductModel>> watchAllProducts() {
    return _productsRef.snapshots().map(_mapSnapshot);
  }

  /// Returns only products where `isActive == true`.
  Future<List<ProductModel>> getActiveProducts() async {
    try {
      final snapshot = await _productsRef.where('isActive', isEqualTo: true).get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching active products');
    }
  }

  /// Returns active products flagged as featured.
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot = await _productsRef
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching featured products');
    }
  }

  /// Returns active products flagged as best sellers.
  Future<List<ProductModel>> getBestSellerProducts() async {
    try {
      final snapshot = await _productsRef
          .where('isActive', isEqualTo: true)
          .where('isBestSeller', isEqualTo: true)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching best seller products');
    }
  }

  /// Returns active products flagged as new arrivals.
  Future<List<ProductModel>> getNewArrivalProducts() async {
    try {
      final snapshot = await _productsRef
          .where('isActive', isEqualTo: true)
          .where('isNewArrival', isEqualTo: true)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching new arrival products');
    }
  }

  /// Returns active products belonging to [categoryId].
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      final snapshot = await _productsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching products by category');
    }
  }

  /// Returns active products belonging to [brandId].
  Future<List<ProductModel>> getProductsByBrand(String brandId) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      final snapshot = await _productsRef
          .where('brandId', isEqualTo: brandId)
          .where('isActive', isEqualTo: true)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw _mapError(e, context: 'fetching products by brand');
    }
  }

  /// Fetches a single product by id.
  Future<ProductModel?> getProductById(String id) async {
    _validateNonEmpty(id, fieldName: 'id');
    try {
      final doc = await _productsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProductModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw _mapError(e, context: 'fetching product by id');
    }
  }

  /// Searches Firestore.
  Future<List<ProductModel>> searchProducts(String keyword) async {
    try {
      final snapshot = await _productsRef.get();
      final all = _mapSnapshot(snapshot);
      final trimmedKeyword = keyword.trim().toLowerCase();
      if (trimmedKeyword.isEmpty) return all;

      return all.where((product) {
        if (product.name.toLowerCase().contains(trimmedKeyword)) return true;
        if (product.description.toLowerCase().contains(trimmedKeyword)) return true;
        if (product.sku.toLowerCase().contains(trimmedKeyword)) return true;
        if (product.brandName.toLowerCase().contains(trimmedKeyword)) return true;
        if (product.categoryName.toLowerCase().contains(trimmedKeyword)) return true;
        if (product.tags.any((t) => t.toLowerCase().contains(trimmedKeyword))) {
          return true;
        }
        if (product.keywords
            .any((k) => k.toLowerCase().contains(trimmedKeyword))) {
          return true;
        }
        return false;
      }).toList();
    } catch (e) {
      throw _mapError(e, context: 'searching products');
    }
  }

  // =========================================================
  // PUBLIC API — CRUD
  // =========================================================

  /// Reserves a new, unused product id.
  String generateProductId() {
    return _productsRef.doc().id;
  }

  /// Creates a new product document.
  Future<void> createProduct(
    ProductModel product, {
    required XFile thumbnailFile,
    required List<XFile> galleryFiles,
  }) async {
    _validateNonEmpty(product.id, fieldName: 'product.id');
    await _validateFileExists(thumbnailFile, fieldName: 'thumbnailFile');
    for (final file in galleryFiles) {
      await _validateFileExists(file, fieldName: 'galleryFile');
    }

    final skuTaken = await skuExists(product.sku);
    if (skuTaken) {
      throw ProductServiceException(
        'A product with SKU "${product.sku}" already exists.',
      );
    }
    final nameTaken = await productNameExists(product.name);
    if (nameTaken) {
      throw ProductServiceException(
        'A product named "${product.name}" already exists.',
      );
    }

    String? thumbnailUrl;
    List<String> galleryUrls = [];

    try {
      // 1. Upload thumbnail
      final thumbName = _storage.generateUniqueFileName(thumbnailFile);
      thumbnailUrl = await _storage.uploadImage(
        file: thumbnailFile,
        path: '$_productsFolder/$thumbName',
      );

      // 2. Upload gallery images
      if (galleryFiles.isNotEmpty) {
        final paths = galleryFiles
            .map((f) => '$_productsFolder/${_storage.generateUniqueFileName(f)}')
            .toList();
        galleryUrls = await _storage.uploadMultipleImages(
          files: galleryFiles,
          paths: paths,
        );
      }

      final now = DateTime.now();
      final populated = product.copyWith(
        thumbnail: thumbnailUrl,
        imageUrls: galleryUrls,
        createdAt: now,
        updatedAt: now,
      );

      await _productsRef.doc(populated.id).set(populated.toMap());
    } on ProductServiceException {
      if (thumbnailUrl != null) await _storage.deleteImage(thumbnailUrl);
      if (galleryUrls.isNotEmpty) await _storage.deleteMultipleImages(galleryUrls);
      rethrow;
    } catch (e) {
      if (thumbnailUrl != null) await _storage.deleteImage(thumbnailUrl);
      if (galleryUrls.isNotEmpty) await _storage.deleteMultipleImages(galleryUrls);
      throw _mapError(e, context: 'creating product');
    }
  }

  /// Updates an existing product document and replaces/cleans up storage files.
  ///
  /// Storage writes and the Firestore write are ordered so a failure never
  /// leaves the two out of sync:
  /// - New thumbnail/gallery files are uploaded as brand-new objects
  ///   (the old ones are left in place for now).
  /// - Only once the Firestore document has been updated successfully are
  ///   the now-unreferenced old files deleted from Storage.
  /// - If anything fails before the Firestore write succeeds (including
  ///   the write itself), any newly-uploaded files are rolled back so
  ///   Storage never ends up with orphaned uploads, and Firestore never
  ///   ends up pointing at a file that was deleted out from under it.
  Future<void> updateProduct(
    ProductModel product, {
    XFile? newThumbnailFile,
    List<XFile>? newGalleryFiles,
  }) async {
    _validateNonEmpty(product.id, fieldName: 'product.id');

    final current = await getProductById(product.id);
    if (current == null) {
      throw ProductServiceException('Product with id "${product.id}" was not found.');
    }

    String? uploadedThumbnailUrl;
    List<String> uploadedGalleryUrls = [];

    try {
      var thumbnailUrl = product.thumbnail;
      if (newThumbnailFile != null) {
        await _validateFileExists(newThumbnailFile, fieldName: 'newThumbnailFile');
        final uniqueName = _storage.generateUniqueFileName(newThumbnailFile);
        thumbnailUrl = await _storage.uploadImage(
          file: newThumbnailFile,
          path: '$_productsFolder/$uniqueName',
        );
        uploadedThumbnailUrl = thumbnailUrl;
      }

      var galleryUrls = List<String>.from(product.galleryImages);
      if (newGalleryFiles != null && newGalleryFiles.isNotEmpty) {
        for (final file in newGalleryFiles) {
          await _validateFileExists(file, fieldName: 'newGalleryFile');
        }

        final paths = newGalleryFiles
            .map((f) => '$_productsFolder/${_storage.generateUniqueFileName(f)}')
            .toList();
        final uploaded = await _storage.uploadMultipleImages(
          files: newGalleryFiles,
          paths: paths,
        );
        uploadedGalleryUrls = uploaded;
        galleryUrls.addAll(uploaded);
      }

      // Files that will become unreferenced once this update lands —
      // only deleted from Storage AFTER the Firestore write below
      // succeeds, so a failed write never leaves Firestore pointing at
      // a file we've already removed.
      final oldThumbnailToRemove =
          (newThumbnailFile != null && current.thumbnail.isNotEmpty)
              ? current.thumbnail
              : null;
      final removedGallery = current.galleryImages
          .where((url) => !galleryUrls.contains(url))
          .toList();

      final updated = product.copyWith(
        thumbnail: thumbnailUrl,
        imageUrls: galleryUrls,
        updatedAt: DateTime.now(),
      );

      await _productsRef.doc(product.id).update(updated.toMap());

      // Firestore write succeeded — now it's safe to clean up the files
      // this update replaced/removed.
      if (oldThumbnailToRemove != null) {
        await _storage.deleteImage(oldThumbnailToRemove);
      }
      if (removedGallery.isNotEmpty) {
        await _storage.deleteMultipleImages(removedGallery);
      }
    } on ProductServiceException {
      if (uploadedThumbnailUrl != null) await _storage.deleteImage(uploadedThumbnailUrl);
      if (uploadedGalleryUrls.isNotEmpty) await _storage.deleteMultipleImages(uploadedGalleryUrls);
      rethrow;
    } catch (e) {
      if (uploadedThumbnailUrl != null) await _storage.deleteImage(uploadedThumbnailUrl);
      if (uploadedGalleryUrls.isNotEmpty) await _storage.deleteMultipleImages(uploadedGalleryUrls);
      throw _mapError(e, context: 'updating product');
    }
  }

  /// Deletes a product's Firestore document and its specific Supabase Storage files.
  Future<void> deleteProduct(String productId) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      final product = await getProductById(productId);
      await _productsRef.doc(productId).delete();

      if (product != null) {
        if (product.thumbnail.isNotEmpty) {
          await _storage.deleteImage(product.thumbnail);
        }
        if (product.galleryImages.isNotEmpty) {
          await _storage.deleteMultipleImages(product.galleryImages);
        }
      }
    } catch (e) {
      throw _mapError(e, context: 'deleting product');
    }
  }

  // =========================================================
  // PUBLIC API — PRODUCT STATUS / INVENTORY
  // =========================================================

  Future<void> toggleProductStatus(String productId, bool isActive) async {
    await _updateSingleField(
      productId,
      field: 'isActive',
      value: isActive,
      context: 'toggling product status',
    );
  }

  Future<void> toggleFeatured(String productId, bool isFeatured) async {
    await _updateSingleField(
      productId,
      field: 'isFeatured',
      value: isFeatured,
      context: 'toggling featured status',
    );
  }

  Future<void> toggleBestSeller(String productId, bool isBestSeller) async {
    await _updateSingleField(
      productId,
      field: 'isBestSeller',
      value: isBestSeller,
      context: 'toggling best seller status',
    );
  }

  Future<void> toggleNewArrival(String productId, bool isNewArrival) async {
    await _updateSingleField(
      productId,
      field: 'isNewArrival',
      value: isNewArrival,
      context: 'toggling new arrival status',
    );
  }

  Future<void> updateStock(String productId, int stock) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    if (stock < 0) {
      throw const ProductServiceException('stock cannot be negative.');
    }
    try {
      await _productsRef.doc(productId).update({
        'stock': stock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: 'updating stock');
    }
  }

  Future<void> increaseSoldCount(String productId, int quantity) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    if (quantity <= 0) {
      throw const ProductServiceException(
        'quantity must be greater than zero.',
      );
    }
    try {
      await _productsRef.doc(productId).update({
        'soldCount': FieldValue.increment(quantity),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: 'increasing sold count');
    }
  }

  // =========================================================
  // PUBLIC API — VALIDATION
  // =========================================================

  Future<bool> productNameExists(String name, {String? excludeId}) async {
    final trimmedName = name.trim();
    _validateNonEmpty(trimmedName, fieldName: 'name');
    try {
      final snapshot = await _productsRef
          .where('name', isEqualTo: trimmedName)
          .limit(5)
          .get();
      return _hasMatchOtherThan(snapshot, excludeId);
    } catch (e) {
      throw _mapError(e, context: 'checking for duplicate product name');
    }
  }

  Future<bool> skuExists(String sku, {String? excludeId}) async {
    final trimmedSku = sku.trim();
    _validateNonEmpty(trimmedSku, fieldName: 'sku');
    try {
      final snapshot =
          await _productsRef.where('sku', isEqualTo: trimmedSku).limit(5).get();
      return _hasMatchOtherThan(snapshot, excludeId);
    } catch (e) {
      throw _mapError(e, context: 'checking for duplicate SKU');
    }
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  List<ProductModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  bool _hasMatchOtherThan(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String? excludeId,
  ) {
    if (excludeId == null) return snapshot.docs.isNotEmpty;
    return snapshot.docs.any((doc) => doc.id != excludeId);
  }

  Future<void> _updateSingleField(
    String productId, {
    required String field,
    required Object? value,
    required String context,
  }) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _productsRef.doc(productId).update({
        field: value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw _mapError(e, context: context);
    }
  }

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw ProductServiceException('$fieldName cannot be empty.');
    }
  }

  Future<void> _validateFileExists(XFile file, {required String fieldName}) async {
    try {
      final len = await file.length();
      if (len == 0) {
        throw ProductServiceException(
          'Missing file: $fieldName is empty.',
        );
      }
    } catch (e) {
      throw ProductServiceException(
        'Missing file: $fieldName does not exist at ${file.path}.',
        e,
      );
    }
  }

  ProductServiceException _mapError(Object error, {required String context}) {
    if (error is ProductServiceException) return error;

    if (error is StorageServiceException) {
      return ProductServiceException(error.message, error);
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return ProductServiceException(
            'Permission denied while $context. Check Firestore/Storage rules.',
            error,
          );
        case 'unavailable':
        case 'network-request-failed':
          return ProductServiceException(
            'Network error while $context. Please check your connection.',
            error,
          );
        case 'not-found':
          return ProductServiceException(
            'Requested data was not found while $context.',
            error,
          );
        default:
          return ProductServiceException(
            'Firebase error while $context: ${error.message ?? error.code}',
            error,
          );
      }
    }

    return ProductServiceException('Unexpected error while $context.', error);
  }
}